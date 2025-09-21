(() => {
  let theme = "github-dark";
  switch (localStorage.getItem("theme")) {
    case "dark-theme":
      theme = "github-dark";
      break;
    case "light-theme":
      theme = "github-light";
      break;
    case "auto":
    default:
      theme = window.matchMedia("(prefers-color-scheme:dark)")
          .matches
        ? "github-dark"
        : "github-light";
      break;
  }
  const s = document.createElement("script");
  s.setAttribute("repo", "ktravis/kylemtravis");
  s.setAttribute("issue-term", "title");
  s.setAttribute("label", "blog-post");
  s.setAttribute("theme", theme);
  s.setAttribute("crossorigin", "anonymous");
  s.setAttribute("async", "");
  s.setAttribute("src", "https://utteranc.es/client.js");
  document.querySelector("#comments").appendChild(s);
})();
