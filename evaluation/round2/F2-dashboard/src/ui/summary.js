export function renderSummary(root, cfg) {
  root.innerHTML = `
    <header><h1>${cfg.title}</h1></header>
    <section class="cards"></section>
  `;
}
