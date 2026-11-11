-- Dock de agentes do OpenBot (borda direita, estilo dock do macOS).
--
-- O OpenBot desenha o dock numa janela própria, flutuante, colada na borda da
-- tela. Sem regra, essa janela pertence ao workspace em que nasceu e fica atrás
-- das outras. Com `pin` ela aparece em todos os workspaces e é desenhada acima
-- das janelas comuns, que é o que o dock precisa para funcionar como o do Mac.
--
-- O match usa `float` para alcançar só a janela do dock: a janela principal do
-- OpenBot não é flutuante e continua com o comportamento normal do tiling.
o.window({ class = "^(openbot)$", float = true }, {
  pin = true,
})
