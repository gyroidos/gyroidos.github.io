/* Fade sections in as they scroll into view (landing page only).
   Progressive enhancement: elements are only hidden after JS tags them,
   so content stays visible without JavaScript. */
(function () {
  if (!document.querySelector(".gy-hero")) return;
  if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
  if (!("IntersectionObserver" in window)) return;

  var selector = [
    ".md-typeset h2",
    ".md-typeset .gy-lead",
    ".md-typeset .gy-two-col",
    ".md-typeset .grid.cards",
    ".md-typeset .gy-contact"
  ].join(", ");

  var observer = new IntersectionObserver(
    function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add("gy-visible");
          observer.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.1, rootMargin: "0px 0px -10% 0px" }
  );

  document.querySelectorAll(selector).forEach(function (el) {
    el.classList.add("gy-reveal");
    observer.observe(el);
  });
})();
