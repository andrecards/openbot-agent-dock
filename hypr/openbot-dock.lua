-- Dock de agentes do OpenBot (borda direita, estilo dock do macOS).
--
-- O OpenBot desenha o dock numa janela própria: transparente, sem moldura e
-- flutuante. Sem regra, ela pertence ao workspace em que nasceu e fica atrás
-- das outras janelas. Com `pin` o dock aparece em todos os workspaces e é
-- desenhado acima das janelas comuns, que é o que ele precisa para funcionar
-- como o dock do Mac.
--
-- O match usa `float` para alcançar só as janelas flutuantes do app: a janela
-- principal do OpenBot não é flutuante e continua com o tiling normal.
--
-- `no_shadow` evita a sombra do compositor em volta de um painel transparente.
-- Não use `no_border` aqui: esse campo só existe em `workspace_rule`; em regra
-- de janela o Hyprland recusa a regra inteira com "unknown field 'no_border'".
o.window({ class = "^(openbot)$", float = true }, {
  pin = true,
  no_shadow = true,
})
