/*
 * Removes the browser splash when Flutter renders its first frame.
 * Author: Ariel Fajimiyo
 * Date: 22/10/26
 */

window.addEventListener(
  'flutter-first-frame',
  () => document.getElementById('lookbook-loader')?.remove(),
  { once: true }
);