/* ===================================================================
   CT226 鐵人三項心得 — 互動腳本
   - 章節捲入淡入 (Intersection Observer)
   - 目錄高亮 (scroll spy)
   - 圖片點擊放大 (Lightbox)
   =================================================================== */

(function () {
  'use strict';

  // ---------- 1. 章節淡入 ----------
  const chapters = document.querySelectorAll('.chapter');
  if ('IntersectionObserver' in window) {
    const io = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add('visible');
          io.unobserve(entry.target);
        }
      });
    }, { threshold: 0.12 });
    chapters.forEach((c) => io.observe(c));
  } else {
    chapters.forEach((c) => c.classList.add('visible'));
  }

  // ---------- 2. 目錄 Scroll Spy ----------
  const tocLinks = document.querySelectorAll('.toc a');
  const sections = Array.from(tocLinks)
    .map((a) => document.querySelector(a.getAttribute('href')))
    .filter(Boolean);

  if ('IntersectionObserver' in window && sections.length) {
    const spyObserver = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          tocLinks.forEach((a) => a.classList.remove('active'));
          const link = document.querySelector(`.toc a[href="#${entry.target.id}"]`);
          if (link) link.classList.add('active');
        }
      });
    }, { rootMargin: '-40% 0px -55% 0px' });
    sections.forEach((s) => spyObserver.observe(s));
  }

  // ---------- 3. Lightbox 點擊放大 ----------
  const lightbox = document.getElementById('lightbox');
  if (!lightbox) return;

  const lbImg = lightbox.querySelector('.lightbox-img');
  const lbCaption = lightbox.querySelector('.lightbox-caption');
  const lbClose = lightbox.querySelector('.lightbox-close');

  function openLightbox(src, captionText, alt) {
    lbImg.src = src;
    lbImg.alt = alt || '';
    lbCaption.textContent = captionText || '';
    lightbox.hidden = false;
    document.body.style.overflow = 'hidden';
  }
  function closeLightbox() {
    lightbox.hidden = true;
    lbImg.src = '';
    document.body.style.overflow = '';
  }

  document.querySelectorAll('.photo, .photo-wide').forEach((fig) => {
    fig.addEventListener('click', () => {
      const img = fig.querySelector('img');
      const cap = fig.querySelector('figcaption');
      if (!img || !img.src || fig.classList.contains('photo-missing')) return;
      openLightbox(img.src, cap ? cap.textContent.trim() : '', img.alt);
    });
  });

  lightbox.addEventListener('click', (e) => {
    if (e.target === lightbox || e.target === lbImg) closeLightbox();
  });
  lbClose.addEventListener('click', closeLightbox);
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !lightbox.hidden) closeLightbox();
  });
})();
