---
name: Generating Shader Code (part 1)
slug: shadergen-pt1
published: 2025-09-21
previewLines: 13
---

Recently I've been...

![initial commit... 2 years ago](/static/images/blog/generating-shader-code-1/initial-commit-2023.png)
Well that's disturbing.

wow, ok, how about *"in the last couple of years"* I've been working on a new project: a game engine written in Rust, mostly from scratch. **To get the obvious out of the way**, I'm writing my own game engine because:

- I want to learn more about modern low-level 3D graphics programming, and
- I **like building the game engine part** more than I like putting the gameplay pieces together in an editor.

If I wanted to actually ship something in an anywhere-reasonable amount of time, I would be using Godot, or Unreal, or even [Bevy](https://bevy.org/), which I really admire and will refer to later on (Not Unity though. Not again). This should hopefully be clear.

I've had moderate success so far, implementing a few core systems like a flexible renderer with support for variable pipelines, a flexible system for defining game inputs, and dynamically scaled text rendering via multi-channel signed distance fields (TODO: future blog post, there's not enough information out there on this). The renderer uses [WGPU](https://wgpu.rs/) to target multiple backends (Vulkan, DirectX12, Metal, WebGPU, ...) and relies heavily on instanced batches to draw tens or hundreds of thousands of sprites at 60fps on my laptop.

To flex and scrutinize some of the graphics pipeline abstractions, I'm working on implementing a few basic but satisfying effects in 3D scenes - shadow mapping, SSAO, depth of field. 

<figure>
    <a href="/static/images/blog/generating-shader-code-1/demo.webm">
<video class="captioned-center-image center-image" src="/static/images/blog/generating-shader-code-1/demo.webm" alt="a little demo of some lighting effects" autoplay loop></video></a>
    <figcaption><p>What does it take to get high(er) quality screen captures? Asking for a friend...</p></figcaption>
</figure>

The current hurdle I'm facing is how to keep data types in sync between rust code and shaders (WGSL). Duplicating and hand-editing both sides in tandem is tedious and error prone; when you violate one of the unintuitive layout rules or forget to change a `vec3` to a `vec4` somewhere it can be quite difficult to debug. It should be possible, if not straightfoward to automate some of this validation and generate some of the glue code for initializing the relevant layouts, buffers, bindings, and data structures. In simpler terms, I want to define types *once* and share them between Rust code and shader code.

I started by researching what existing approaches did. Many WGPU or WebGPU examples are too simple to bother with streamlining these pieces, and those that are more complex are usually doing something highly specialized. One approach is "shader-first": writing WGSL and using that to generate Rust types. There are clear benefits - shader code is more specialized, so it helps to retain control over it. Generally if you can express a type in the shader, it should be representable in Rust.

The biggest drawback is that WGSL is *very limited*, missing things like a standardized way to organize and share code between multiple shader units. You end up copying types and functions between every shader, needing to keep them synchronized manually. Efforts like [WESL](https://wesl-lang.dev/) exist to provide some of the missing pieces (standardized syntax for imports, for example), but they are early and in flux. I don't doubt the promise of these projects, but they don't solve my problem just yet.

### WWBD?

We know the very flexible Bevy uses WGPU also - what does it do?

Bevy defines the [`naga-oil`](https://github.com/bevyengine/naga_oil) crate as a pre-processor layer, which mostly consists of [using regex to parse custom directives](https://github.com/bevyengine/naga_oil/blob/2f9742337c734e5a93962f6e477b73088a563d57/src/compose/preprocess.rs#L13-L55) from the WGSL source, modifying it, and then emitting a complete shader.

See the [post-processing example](https://bevy.org/examples/shaders/custom-post-processing/), which reuses an existing `FullscreenVertexOutput` builtin definition:

```wgsl
#import bevy_core_pipeline::fullscreen_vertex_shader::FullscreenVertexOutput

@group(0) @binding(0) var screen_texture: texture_2d<f32>;
@group(0) @binding(1) var texture_sampler: sampler;
struct PostProcessSettings {
    intensity: f32,
#ifdef SIXTEEN_BYTE_ALIGNMENT
    // WebGL2 structs must be 16 byte aligned.
    _webgl2_padding: vec3<f32>
#endif
}
@group(0) @binding(2) var<uniform> settings: PostProcessSettings;

@fragment
fn fragment(in: FullscreenVertexOutput) -> @location(0) vec4<f32> {
    // Chromatic aberration strength
    let offset_strength = settings.intensity;

    // Sample each color channel with an arbitrary shift
    return vec4<f32>(
        textureSample(screen_texture, texture_sampler, in.uv + vec2<f32>(offset_strength, -offset_strength)).r,
        textureSample(screen_texture, texture_sampler, in.uv + vec2<f32>(-offset_strength, 0.0)).g,
        textureSample(screen_texture, texture_sampler, in.uv + vec2<f32>(0.0, offset_strength)).b,
        1.0
    );
}
```

The shader also makes use of preprocessor `#ifdef` conditionals, and defines `PostProcessSettings` for bound pipeline data. This struct must also be defined on the Rust side:

```rust
#[derive(Component, Default, Clone, Copy, ExtractComponent, ShaderType)]
struct PostProcessSettings {
    intensity: f32,
    // WebGL2 structs must be 16 byte aligned.
    #[cfg(feature = "webgl2")]
    _webgl2_padding: Vec3,
}
```

So unfortunately we still have duplication, though Bevy does provide some helpful derive macros like [`AsBindGroup`](https://docs.rs/bevy/latest/bevy/render/render_resource/trait.AsBindGroup.html) that eliminates some of the WGPU verbosity (bind group layout descriptor creation).

*As an aside:* I think this approach is probably the right tradeoff for something like Bevy - it's reasonably simple for the end-user, handling most of the complexity in the core engine.

If we take as our main objective automating the synchronization of types between Rust and WGPU, what can we accomplish?

## Shader-First (Generating Rust)

There is some prior art in the area of using WGSL to generate Rust, particularly:

- [naga-to-tokenstream](https://github.com/LucentFlux/naga-to-tokenstream), which takes a shader as input and generates a Rust module containing types, constants, and other metadata like bind group info.
- [include-wgsl-oil](https://github.com/LucentFlux/include-wgsl-oil), which builds on the former and `naga-oil` to preprocess included WGSL files before generating Rust code.

Ultimately this lets you do something like:

```wgsl
@export struct MyStruct {
    foo: u32,
    bar: i32
}
```

in your shader, and

```rust
#[include_wgsl_oil::include_wgsl_oil("path/to/shader.wgsl")]
mod my_shader { }

let my_instance = my_shader::types::MyStruct {
    foo: 12,
    bar: -7
};
```

in Rust.

Great, this is what we were after! I forked each to suit my needs slightly more - `naga-to-tokenstream` supports [`encase`](https://docs.rs/encase/latest/encase/) which generates conversion functions for Rust types in the default representation to a GPU-compatible layout, specifically matching WGSL's memory layout requirements (alignment, etc). To avoid obfuscating any performance issues, my engine prefers that types used in the renderer require no conversion, instead using [`bytemuck`](https://docs.rs/bytemuck/latest/bytemuck/) to "cast" into byte slices for upload to the GPU.

```rust
// An example of using `encase` to generate conversion functions:
use encase::{ShaderType, UniformBuffer};

#[derive(ShaderType)]
struct AffineTransform2D {
    matrix: test_impl::Mat2x2f,
    translate: test_impl::Vec2f,
}

// UniformBuffer encapsulates (encases?) the actual data transformation 
let mut buffer = UniformBuffer::new(Vec::<u8>::new());
buffer.write(&AffineTransform2D {
    matrix: test_impl::Mat2x2f::IDENTITY,
    translate: test_impl::Vec2f::ZERO,
}).unwrap();
// byte_buffer can now be passed directly to WGPU
let byte_buffer = buffer.into_inner();
// ...

// An example of using bytemuck to copy types as-is:
#[repr(C)]
#[derive(Debug, Clone, Copy, bytemuck::Pod, bytemuck::Zeroable)]
pub struct BasicInstanceData {
    pub subtexture: Rect,
    pub tint: Color,
    pub transform: Mat4,
}

let instances = &[
    BasicInstanceData{
        tint: Color::RED,
        transform: Mat4::from_translation(vec3(1.0, 0.0, 2.0)),
        ..Default::default()
    },
];
let byte_slice: &[u8] = bytemuck::cast_slice(instances);

```

I also modified `generate-wgsl-oil` to run in a build script rather than as an attribute macro:

```rust
use generate_wgsl_oil::generate_from_entrypoints;

// simplified build script example
fn main() {
    let dir = std::path::Path::new("res/shaders/");
    let mut shader_paths = vec![];
    for res in dir.read_dir().expect("failed to open res/shaders/") {
        if let Ok(entry) = res {
            shader_paths.push(entry.path().to_string_lossy().into_owned());
        }
    }
    let result = generate_from_entrypoints(&shader_paths);
    std::fs::write("src/renderer/shaders.rs", result).unwrap();
}
```

When the crate is compiled, `build.rs` reads included WGSL files and generates Rust structs for any types marked with `@export`.

Shader:
```wgsl
// deferred_lighting.wgsl
@export
struct Light {
    position: vec4<f32>,
    color: vec4<f32>,
    view_proj: mat4x4<f32>,
}

@export
struct LightsUniform {
    items: array<Light, 8>,
    count: u32,
}

// ...
```

Generated Rust:
```rust
pub mod deferred_lighting {
    ///Equivalent Rust definitions of the types defined in this module.
    pub mod types {
        #[allow(unused, non_camel_case_types)]
        #[repr(C)]
        #[derive(Debug, PartialEq, Copy, Clone, bytemuck::Pod, bytemuck::Zeroable)]
        pub struct Light {
            pub position: glam::f32::Vec4,
            pub color: glam::f32::Vec4,
            pub view_proj: glam::f32::Mat4,
        }
        #[allow(unused, non_camel_case_types)]
        #[repr(C)]
        #[derive(Debug, PartialEq, Copy, Clone, bytemuck::Pod, bytemuck::Zeroable)]
        pub struct LightsUniform {
            pub items: [Light; 8u32 as usize],
            pub count: u32,
            pub _pad: [u8; 12u32 as usize],
        }
    }
    // ...
}
```

### Aside: Automatic Alignment

One big pro of this approach is being able to generate padding easily - all of this nonsense can be hidden away:

<details>
<summary>(nonsense)</summary>

```rust
let mut layouter = Layouter::default();
layouter.update(module.to_ctx()).unwrap();

let members_have_names = members.iter().all(|member| member.name.is_some());
let mut last_field_name = None;
let mut total_offset = 0;
let mut largest_alignment = 0;

let mut members: Vec<_> = members
    .iter()
    .enumerate()
    .map(|(i_member, member)| {
        let member_name = if members_have_names {
            let member_name =
                member.name.as_ref().expect("all members had names").clone();
            syn::parse_str::<syn::Ident>(&member_name)
        } else {
            syn::parse_str::<syn::Ident>(&format!("v{}", i_member))
        };

        self.rust_type_ident(member.ty, module, args).and_then(|member_ty| {
            member_name.ok().map(|member_name| {
                let inner_type = module
                    .types
                    .get_handle(member.ty)
                    .expect("failed to locate member type")
                    .inner
                    .clone();
                let field_size = inner_type.size(module.to_ctx());
                let alignment = layouter[member.ty].alignment * 1u32;
                largest_alignment = largest_alignment.max(alignment);
                let padding_needed =
                    layouter[member.ty].alignment.round_up(total_offset)
                        - total_offset;
                let pad = if padding_needed > 0 {
                    let padding_member_name = format_ident!(
                        "_pad_{}",
                        last_field_name.as_ref().expect(
                            "invariant: expected prior member before padding field"
                        )
                    );
                    quote::quote! {
                        pub #padding_member_name: [u8; #padding_needed as usize],
                    }
                } else {
                    quote::quote! {}
                };
                total_offset += field_size + padding_needed;
                last_field_name = Some(member_name.clone());
                quote::quote! {
                    #pad
                    pub #member_name: #member_ty
                }
            })
        })
    })
    .collect();

// Some final padding may be needed to ensure a packed version of the struct
// has proper overall alignment, which is determined by the largest among
// individual field alignment requirements
let struct_alignment = Alignment::from_width(largest_alignment as u8);
if !struct_alignment.is_aligned(total_offset) {
    // struct needs padding to be aligned
    let padding_needed = struct_alignment.round_up(total_offset) - total_offset;
    members.push(Some(quote::quote! {
        pub _pad: [u8; #padding_needed as usize],
    }));
}

// ...

syn::parse_quote! {
    #[repr(C)]
    #[derive(Debug, PartialEq, Copy, Clone)]
    pub struct #struct_name {
        #(#members ,)*
    }
}
```
</details>

## What's the catch

I actually went quite far with this approach, eliminating more and more boilerplate and repetition with codegen, extending what was now "WGSL" in airquotes to support more and more of the ergonomics you'd want: namespacing, imports, macros, etc. - trying to turn it into a first-class programming language, which it is not. I contemplated forking the language server to add support for the different pre-processor directives and stop my editor from complaining (we are like 3 levels deep in the Hal-changing-a-lightbulb-recursion at this point). 

Ultimately I found myself unsatisfied with one significant aspect of this approach - and (perhaps surprisingly) it wasn't the amount of busywork I had created.

The problem now is that despite **Rust types being what we'll interact with the most**, we have limited control over them and lose a lot of expressiveness; **WGSL types are far simpler** (by design). With this implementation, these basic WGSL types can only have one corresponding Rust representation - a WGSL `vec4<f32>` is always a Rust `glam::Vec4`, for example. To make the difficulty this imposes more concrete, consider the following case.

### Instancing Matrices

It is common in graphics programming to have per-vertex data, and optionally *per-instance* data, both of which are [stored in vertex buffers](https://webgpufundamentals.org/webgpu/lessons/webgpu-vertex-buffers.html#a-instancing). The per-vertex data the shader acts on changes with every - you guessed it - vertex, but the programmer has control over how these vertices are grouped into instances. This is a way to define "per-object" (or per-mesh) data without duplicating it for each vertex.

```wgsl
struct VertexInput {
    @location(0) position: vec4<f32>,
    @location(1) tex_coords: vec2<f32>,
}

struct InstanceInput {
    // example instance data: a color value to be applied to every vertex
    @location(2) tint: vec4<f32>,
}

@vertex
fn main(
    // when rendering triangles, we might have three different VertexInputs for
    // each InstanceInput
    vertex: VertexInput,
    instance: InstanceInput,
) -> @builtin(position) vec4<f32> {
    // ...
}
```

There are differences in the data structures supported by vertex buffers in WebGPU, or at least in the way the shader can access that data. Most notably in our case, they can't contain a matrix - but if you wanted, for example, a 4x4 matrix, you could just put 4 `vec4f`s in the vertex data structure, and then reconstruct from these columns (or rows).

I wrote the renderer relying heavily on instancing, with 2 4x4 matrices in the instance data structure, so that means the structs for instance data in shaders look something like this:

```wgsl
struct Instance {
  ...
  model_1: vec4f,
  model_2: vec4f,
  model_3: vec4f,
  model_4: vec4f,
  normal_1: vec4f,
  normal_2: vec4f,
  normal_3: vec4f,
  normal_4: vec4f,
};
```

and I manually transform these into the desired `mat4x4`:

```wgsl
@vertex
fn vs_main(
    vertex: ModelVertexData,
    instance: InstanceInput,
) -> VertexOutput {
    let model_transform = mat4x4<f32>(
        instance.model_1,
        instance.model_2,
        instance.model_3,
        instance.model_4,
    );
    let normal_matrix = mat4x4<f32>(
        instance.normal_1,
        instance.normal_2,
        instance.normal_3,
        instance.normal_4,
    );
    // ...
}
```

Cumbersome, but we'll deal with it.

---

Back to why this makes things difficult: if I'm letting the shader be the source of truth and automating the creation of compatible types, that means I'm generating a rust struct with 4 `glam::Vec4`'s when previously I would manually define it as a single `glam::Mat4` (which the actual bytes are equivalent to), and that's much easier to work with.

```rust
// Alternatively we could call this `InstanceRaw` and immediately 
// transform into an Instance struct with a Mat4
struct Instance {
    // ...
    model_1: glam::Vec4,
    model_2: glam::Vec4,
    model_3: glam::Vec4,
    model_4: glam::Vec4,
}

impl Instance {
    // Now everything we do has to go through helper methods
    fn model_matrix(&self) -> glam::Mat4 {
        glam::Mat4::from_cols(self.model_1, self.model_2, self.model_3, self.model_4)
    }

    fn set_model_matrix(&mut self, m: glam::Mat4) {
        let [col1, col2, col3, col4] = m.to_cols_array_2d(); 
        self.model_1 = col1.into(); // convert from [f32; 4] to Vec4
        self.model_2 = col2.into();
        self.model_3 = col3.into();
        self.model_4 = col4.into();
    }
}
```

I _could_ accept that I'll need to map between a usable type and a raw type but that defeats the purpose of trying to share types in the first place, and goes against our optimization goal of avoiding a data transmutation step.

I'd like a way to indicate on the shader struct that says "this should be a matrix, actually" when I generate the rust type for it. I could make another directive for the pre-processor:

```wgsl
struct Instance {
  ...
  //!union: mat4x4
  model_1: vec4f,
  model_2: vec4f,
  model_3: vec4f,
  model_4: vec4f,
};
```

and infer that I should "consume" as many fields following the tag as would be equivalent bytes. Annoyingly I don't have an easy way to associate that tag with that particular field in the struct definition when doing the pre-processing (it's all [driven by straightforward regex](https://github.com/LucentFlux/include-wgsl-oil/blob/b05bce5df690cee21860504392eec92f417368a8/src/exports.rs#L19), after all). To make matters worse, there is no easy approach to retrieve the sizes of these types during compilation.

We could do something "clever" or very hard-coded here (perhaps some magic naming convention for fields that should be consolidated), but **I'm here to write rust so let's do that instead.**

## Rust-First (Generating WGSL)

Toss all that out.

![Ron Swanson throws out his computer.](/static/images/blog/generating-shader-code-1/ron_swanson_trashes_computer_small.jpg)
Ron was right.

Why not use Rust procedural macros to generate WGSL shader code and validate that types are compatible? What if we could write something like the following:

```rust
#[repr(C)]
#[derive(ShaderType, VertexDataType, VertexInput)]
struct InstanceData {
    // Rect contains two Vec2s
    pub subtexture: Rect,
    pub tint: Color,
    pub transform: Mat4,
    pub normal_matrix: Mat4,
}
let shader = compile_shader(ShaderInfo{
    // Just some strings to prepend the shader body with
    shared_types: &[
        InstanceData::definition(),
        // ...
    ],
    source: include_bytes!("res/shaders/my-shader.wgsl"),
});
```

With a relatively simple proc macro to generate that `definition` method, that just iterates over the struct fields, expanding each into zero or more attributes:

```rust
#[proc_macro_derive(VertexInput)]
pub fn derive_vertex_input_type(ts: proc_macro::TokenStream) -> proc_macro::TokenStream {
    let input = syn::parse_macro_input!(ts as DeriveInput);
    let Data::Struct(data) = &input.data else {
        return Error::new_spanned(input, "VertexInput can only be derived on a struct.")
            .into_compile_error()
            .into();
    };
    let struct_ident = input.ident.clone();
    let string_name = struct_ident.to_string();
    let fields = data.fields.iter().map(|f| {
        let ty = &f.ty;
        let name = f.ident.as_ref().unwrap().to_string();
        // assume `VertexDataType::wgsl_fields` as some default method that expands
        // a set of user-defined `VertexDataType::attributes` on the type
        quote_spanned!(ty.span()=> <#ty as VertexDataType>::wgsl_fields(#name))
    });

    quote_spanned! {input.span()=>
        impl VertexInput for #struct_ident {
            fn definition() -> String {
                let struct_fields = [
                        #(#fields,)*
                ].concat()
                    .iter()
                    .map(|s| format!("{},", s))
                    .collect::<String>();
                format!("struct {} {{ {} }}", #string_name, struct_fields)
            }
        }
    }
    .into()
}
```

And with that, our final output could be (formatted):

```wgsl
struct InstanceInput { 
    // Expanded from Rect into its components
    subtexture_pos: vec2<f32>,
    subtexture_scale: vec2<f32>,
    tint: vec4<f32>,
    // Our flattened Mat4s
    transform_1: vec4<f32>,
    transform_2: vec4<f32>,
    transform_3: vec4<f32>,
    transform_4: vec4<f32>,
    normal_matrix_1: vec4<f32>,
    normal_matrix_2: vec4<f32>,
    normal_matrix_3: vec4<f32>,
    normal_matrix_4: vec4<f32>, 
}
```

We then have the power of Rust's type system at our disposal - need to expand a `Mat4` to four vectors when it's used in vertex data? Easy:

```rust
impl VertexDataType for Mat4 {
    fn attributes() -> Vec<String> {
        vec![<Vec4 as ShaderType>::wgsl_name(); 4]
    }
}
```

We're of course free to reuse type definitions in both the vertex and non-vertex data contexts, or specialize like in this case.

### Next Steps

Alignment validation can still be accomplished at compile time by emitting `compile_error!(...)` from our macro if a static assertion fails (more on that later) - or we could even generate padding automatically (if we opt for an attribute macro rather than a derive).

What if we want to parse and validate the shader at compile time, too? Projects like [wgsl-inline](https://crates.io/crates/wgsl-inline) show how that can be achieved, provided we have a string literal of the source. As for how we go from a trait implementation that returns strings to a solution with enough (const) type information to run type-checking at compilation time, I'll go over that in *part 2 (coming soon).*
