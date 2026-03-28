var viewportWidth = window.innerWidth || document.documentElement.clientWidth;
if (viewportWidth > 991) {
const animateElements = document.querySelectorAll('.animate-fadeIn');
const animateElements2 = document.querySelectorAll('.animate-fadeInUp');
const animateElements3 = document.querySelectorAll('.animate-fadeInLeft');
const animateElements4 = document.querySelectorAll('.animate-fadeInRight');
const animateElements5 = document.querySelectorAll('.animate-fadeInDown');
const animateElements6 = document.querySelectorAll('.animate-zoom');
const animateElements7 = document.querySelectorAll('.animate-bounce');
const animateElements8 = document.querySelectorAll('.animate-bounceUp');
const animateElements9 = document.querySelectorAll('.animate-flip');
animateObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.intersectionRatio > 0) {
      entry.target.classList.add('fancy','animated');
      animateObserver.unobserve(entry.target);
    } else {
      entry.target.classList.remove('fancy','animated');
    }
  });
},{threshold: 0.1});
animateElements.forEach(animateElement => {
  animateObserver.observe(animateElement);
});
animateElements2.forEach(animateElement => {
  animateObserver.observe(animateElement);
});
animateElements3.forEach(animateElement => {
  animateObserver.observe(animateElement);
});
animateElements4.forEach(animateElement => {
  animateObserver.observe(animateElement);
});
animateElements5.forEach(animateElement => {
  animateObserver.observe(animateElement);
});
animateElements6.forEach(animateElement => {
  animateObserver.observe(animateElement);
});
animateElements7.forEach(animateElement => {
  animateObserver.observe(animateElement);
});
animateElements8.forEach(animateElement => {
  animateObserver.observe(animateElement);
});
animateElements9.forEach(animateElement => {
  animateObserver.observe(animateElement);
});
}
