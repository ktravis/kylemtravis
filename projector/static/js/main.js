$(document).ready(function () {
    $(".drop-in").hide().each(function (i, el) {
        $(el).delay(i*350).slideDown();
    });
    setTwitterExpandCallback();
});

function setTwitterExpandCallback()
{
    $("#twitter-widget-expand").click(function () {
        $("i",this).attr("class", "fa fa-chevron-up fa-lg");
        $(this).after(
                '<a class="twitter-timeline" width="300" height="240" href="https://twitter.com/kmakai" data-widget-id="464453798119747584"></a>');
        window.twttr = (function (d, s, id) {
        var t, js, fjs = d.getElementsByTagName(s)[0];
        if (d.getElementById(id)) return;
        js = d.createElement(s); js.id = id; js.src= "https://platform.twitter.com/widgets.js";
        fjs.parentNode.insertBefore(js, fjs);
        return window.twttr || (t = { _e: [], ready: function (f) { t._e.push(f) } });
        }(document, "script", "twitter-wjs"));

        setTwitterContractCallback();
    });
}
function setTwitterContractCallback()
{
    $("#twitter-widget-expand").unbind("click").on("click", function () {
        $(".twitter-timeline").slideToggle();
        $("i",this).toggleClass("fa-chevron-down").toggleClass("fa-chevron-up");
    });
}
