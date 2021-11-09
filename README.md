# LF_Prediction

## Sobre
  O projeto foi proposto para a disciplina de Processamento digital de imagens e tem como objetivo implementar preditores em ***Light Field***. Os modos de predição implementados foram o modo vertical, modo horizontal e modo DC seguindo os modelos presentes em [H.264/AVC](https://www.vcodex.com/h264avc-intra-precition/).

## Modo de uso

 1. Primeiramente deve-se executar o arquivo `PathSetup.m`
Esse arquivo faz a configuração dos diretórios utilizados no projeto
execute:
```
PathSetup
```

 2. Em seguida execute o script `LightFieldPrediction.m` 
 Esse arquivo executa o código dos preditores e vai abrir um pop-up para escolher o diretório onde se encontram os arquivos no formato PPM
 execute:
 ```
LightFieldPrediction
```
O script vai executar todos os modos de predição como default porém é possível setar um modo de predição alterando o último parâmetro da função *PredictBlock* ( v - Vertical | h - Horizontal | dc - DC | all - todos )