import hljs from 'highlight.js';

const toCodeblock = (str) => {
  try {
    const doc = new DOMParser().parseFromString(str, 'text/html');

    doc.querySelectorAll('code').forEach((el) => {
      el.classList.add('hljs');
      if (el.dataset.language && !el.dataset.highlighted) {
        el.innerHTML = hljs.highlight(el.dataset.language, el.innerHTML).value;
        el.dataset.highlighted = true;
      }
    })

    doc.querySelectorAll('p').forEach((el) => {
      if (el.innerHTML.length === 0) {
        el.remove();
      }
    });

    return doc.body.innerHTML;
  } catch(e) {
    return str;
  }
}

export default function codeblockify(text) {
  return toCodeblock(text);
};
