// this makes the cover of the document
#include "src/cover.typ"
// Set up for the rest of document
#set text(size: 11pt)
#show link: underline
#counter(page).update(1)
#set page(paper: "a4", header: [Jonas Möwes #h(1fr) IDP #h(1fr) Hochschule für Technik], numbering: "-1-")
#set heading(numbering: "1.")
#include "src/introduction.typ"
#include "src/risc_v.typ"
#include "src/qemu.typ"
#include "src/bare_metal.typ"
#include "src/rtems.typ"
#include "src/milestones.typ"
#include "src/conclusion.typ"
#include "src/sources.typ"
