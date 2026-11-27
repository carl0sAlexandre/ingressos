## Ferramentas

### PHP-FPM

Ele funciona como um gerenciador de processos, administrando os processos PHP e tratando as requisições PHP separadamente do servidor web. Dessa forma, ele consegue lidar com múltiplas requisições PHP simultaneamente

Outra alteranativa seria o PHP-CGI (Common Gateway Interface) tradicional mas o php-fpm supera ele na limitações.

### Docker

ela pode ser instanciada como container em qualquer ambiente que desejar. Isso significa que poderá utilizar sua aplicação no notebook do desenvolvedor da mesma forma que seria executada no servidor de produção. 

Assim ela não da o famoso problema "na minha maquina funciona" pois eles funcionam da mesma forma.

Outra alterarnativa de gerenciador de contêineres **Kubernetes** mas ele operar de forma diferente do **docker** e foi projetado para orquestração de contêineres
