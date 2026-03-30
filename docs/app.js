// Theme
(function () {
  var root = document.documentElement;
  var toggle = document.querySelector(".theme-toggle");
  var prefersDark = window.matchMedia("(prefers-color-scheme: dark)");

  function applyTheme(theme) {
    root.dataset.theme = theme;
  }

  function getEffectiveTheme() {
    var stored = localStorage.getItem("theme");
    if (stored) return stored;
    return prefersDark.matches ? "dark" : "light";
  }

  applyTheme(getEffectiveTheme());

  if (toggle) {
    toggle.addEventListener("click", function () {
      var next = root.dataset.theme === "dark" ? "light" : "dark";
      localStorage.setItem("theme", next);
      applyTheme(next);
    });
  }

  prefersDark.addEventListener("change", function () {
    if (!localStorage.getItem("theme")) {
      applyTheme(prefersDark.matches ? "dark" : "light");
    }
  });
})();

// Scroll reveal
var revealNodes = document.querySelectorAll(".reveal");

if ("IntersectionObserver" in window) {
  var revealObserver = new IntersectionObserver(
    function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add("visible");
          revealObserver.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.15 }
  );

  revealNodes.forEach(function (node, index) {
    node.style.transitionDelay = Math.min(index * 80, 350) + "ms";
    revealObserver.observe(node);
  });
} else {
  revealNodes.forEach(function (node) {
    node.classList.add("visible");
  });
}

// Tabs
var tabButtons = document.querySelectorAll(".tab-btn");
var tabPanels = document.querySelectorAll(".tab-panel");

tabButtons.forEach(function (button) {
  button.addEventListener("click", function () {
    tabButtons.forEach(function (item) {
      item.classList.remove("active");
      item.setAttribute("aria-selected", "false");
    });
    tabPanels.forEach(function (panel) {
      panel.classList.remove("active");
      panel.hidden = true;
    });

    button.classList.add("active");
    button.setAttribute("aria-selected", "true");
    var panel = document.getElementById(button.dataset.target);
    if (!panel) return;
    panel.classList.add("active");
    panel.hidden = false;
  });
});

// Lightbox
var lightbox = document.getElementById("lightbox");
var lightboxImg = document.getElementById("lightbox-img");

function openLightbox(src, alt) {
  lightboxImg.src = src;
  lightboxImg.alt = alt;
  lightboxImg.classList.remove("zoomed");
  lightbox.hidden = false;
  document.body.style.overflow = "hidden";
}

function closeLightbox() {
  lightbox.hidden = true;
  lightboxImg.src = "";
  document.body.style.overflow = "";
}

document.querySelectorAll(".preview-card img").forEach(function (img) {
  img.addEventListener("click", function () {
    openLightbox(img.src, img.alt);
  });
});

lightbox.addEventListener("click", function (e) {
  if (e.target === lightboxImg) {
    lightboxImg.classList.toggle("zoomed");
  } else {
    closeLightbox();
  }
});

document.addEventListener("keydown", function (e) {
  if (e.key === "Escape" && !lightbox.hidden) {
    closeLightbox();
  }
});

// Feature modal
var featureModal = document.getElementById("feature-modal");
var featureModalBody = document.getElementById("feature-modal-body");
var featureModalCloseBtn = document.getElementById("feature-modal-close");
var featureModalBackdrop = document.getElementById("feature-modal-backdrop");
var featureCards = document.querySelectorAll(".feature-card[role='button']");
var activeFeatureCard = null;

function openFeatureModal(card) {
  var title = card.querySelector("h3").outerHTML;
  var details = card.querySelector(".feature-details").innerHTML;

  featureModalBody.innerHTML = title + details;
  featureModal.hidden = false;
  activeFeatureCard = card;

  void featureModal.offsetWidth;
  featureModal.classList.add("active");
  document.body.style.overflow = "hidden";
  featureModalCloseBtn.focus();
}

function closeFeatureModal() {
  featureModal.classList.remove("active");
  setTimeout(function () {
    if (!featureModal.classList.contains("active")) {
      featureModal.hidden = true;
      featureModalBody.innerHTML = "";
      document.body.style.overflow = "";
      if (activeFeatureCard) {
        activeFeatureCard.focus();
        activeFeatureCard = null;
      }
    }
  }, 300);
}

featureCards.forEach(function (card) {
  card.addEventListener("click", function () {
    openFeatureModal(card);
  });
  card.addEventListener("keydown", function (e) {
    if (e.key === "Enter" || e.key === " ") {
      e.preventDefault();
      openFeatureModal(card);
    }
  });
});

if (featureModalCloseBtn) {
  featureModalCloseBtn.addEventListener("click", closeFeatureModal);
}
if (featureModalBackdrop) {
  featureModalBackdrop.addEventListener("click", closeFeatureModal);
}

document.addEventListener("keydown", function (e) {
  if (e.key === "Escape" && featureModal && !featureModal.hidden) {
    closeFeatureModal();
  }
});
