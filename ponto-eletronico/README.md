Algumas observações para fazer a BUILD

1)Atualizar a versão do package.json
npm version patch

2)Fazer a build usando o comando de controle de cache
ng build --aot --output-hashing=all

3)Caso seja necessario fazer o seu computador de server temporario para teste use o comando abaixo
ng serve --host <seu ip> --port <porta onde vc quer disponibilizar o serviço, caso nao informe a porta padrao é 4200>
Exemplo1: ng serve --host 192.168.46.79
Exemplo2: ng serve --host 192.168.46.79 --port 3000