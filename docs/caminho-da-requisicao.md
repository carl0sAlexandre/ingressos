# O que acontece quando o comprador aperta Enter
O comprador ao acessar o endereço do site e apertar enter, Descobre o IP do servidor o DNS no caso e faz o pedido para o servidor HTTP,
No meu servidor a requisição passa pelo nginx e pelo php-fpm que configurei para acessar somente o arquivo index.php e não conseguir acessar nenhum arquivo dentro do codigo.  

## 1. DNS:

DNS e o nome do endereço, traduz nomes dos sites para uma forma que os humanos entendam e ficam mais simples de lembrar e depois tranformam no endereço de IP para os computadores conseguir se localizar na rede.

```text
; <<>> DiG 9.18.39-0ubuntu0.24.04.9-Ubuntu <<>> www.youtube.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 58502
;; flags: qr rd ra; QUERY: 1, ANSWER: 8, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;; ANSWER SECTION:
www.youtube.com.        27      IN      A       142.251.156.4
;; Query time: 2 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Fri Nov 27 08:50:57 -03 2026
;; MSG SIZE  rcvd: 172
```

- `status: NOERROR`: o nome existe, não possui erro.
- `A 142.251.156.4`: é o endereço IPv4 do youtube.
- `27`: é o TTL, em segundos. É quanto tempo essa resposta ainda pode ficar em cache. Se tiver troca esssa resposta demora 300 segundos para poder ser buscada novamente.
- `127.0.0.53#53(127.0.0.53)`: quem respondeu foi o resolvedor local do Ubuntu.
- `Query time: 2 msec`: foi rápido porque veio do cache. 

## 2. TLS: conexão segura e confiança

O cliente abre uma conexão TCP na porta 443 e negocia o TLS. O `openssl s_client` mostra a cadeia de certificados:

```text
Certificate chain
 0 s:CN = *.google.com
   i:C = US, O = Google Trust Services, CN = WE2
   a:PKEY: id-ecPublicKey, 256 (bit); sigalg: ecdsa-with-SHA256
   v:NotBefore: Nov  3 08:26:50 2026 GMT; NotAfter: Jan 26 08:26:49 2027 GMT
 1 s:C = US, O = Google Trust Services, CN = WE2
   i:C = US, O = Google Trust Services LLC, CN = GTS Root R4
   a:PKEY: id-ecPublicKey, 256 (bit); sigalg: ecdsa-with-SHA384
   v:NotBefore: Dec 13 09:00:00 2023 GMT; NotAfter: Feb 20 14:00:00 2029 GMT
 2 s:C = US, O = Google Trust Services LLC, CN = GTS Root R4
   i:C = BE, O = GlobalSign nv-sa, OU = Root CA, CN = GlobalSign Root CA
   a:PKEY: id-ecPublicKey, 384 (bit); sigalg: RSA-SHA256
   v:NotBefore: Nov 15 03:43:21 2023 GMT; NotAfter: Jan 28 00:00:42 2028 GMT
---
Verify return code: 0 (ok)
---
New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
```

Em cada certificado, `s:` é o dono e `i:` é quem assinou.

A versão negociada foi o `TLSv1.3`, que faz o handshake (aperto de mão) numa única ida e volta, contra duas do TLS 1.2.

## 3. HTTP: o pedido e a resposta

O `curl -v` mostra a conversa inteira. Linhas com `*` são informações do curl, `>` é o que foi enviado e `<` é o que chegou:

```text
Host www.youtube.com:80 was resolved.
* IPv6: 2001:4860:4828:400::, 2001:4860:482d:400::, 2001:4860:482c:400::, 2001:4860:4826:400::, 2001:4860:4827:400::, 2001:4860:482b:400::, 2001:4860:4829:400::, 2001:4860:482a:400::
* IPv4: 142.251.157.4, 142.251.150.4, 142.251.155.4, 142.251.156.4, 142.251.152.4, 142.251.154.4, 142.251.153.4, 142.251.151.4
*   Trying 142.251.157.4:80...
* Connected to www.youtube.com (142.251.157.4) port 80
> GET / HTTP/1.1
> Host: www.youtube.com
> User-Agent: curl/8.5.0
> Accept: */*
> 
< HTTP/1.1 301 Moved Permanently
< Content-Type: application/binary
< X-Content-Type-Options: nosniff
< Cache-Control: no-cache, no-store, max-age=0, must-revalidate
< Pragma: no-cache
< Expires: Mon, 01 Jan 1990 00:00:00 GMT
< Date: Fri, 27 Nov 2026 11:58:23 GMT
< Location: https://www.youtube.com/
< Server: ESF
< Content-Length: 0
< X-XSS-Protection: 0
< X-Frame-Options: SAMEORIGIN
< 
* Connection #0 to host www.youtube.com left intact
```

- `content-type: text/html; charset=utf-8`: o corpo é uma página HTML em UTF-8.
- `cache-control: max-age=0, private, must-revalidate`: a página não pode ficar em cache compartilhado e precisa ser confirmada com o servidor antes de ser reaproveitada, porque ela muda conforme quem está logado.
- `strict-transport-security: max-age=31536000`: durante um ano, o navegador só deve acessar o GitHub por HTTPS.

## 4. No meu ambiente: nginx, FastCGI, PHP-FPM e index.php

No meu projeto não tem DNS público nem TLS, porque ele roda só na minha máquina. A requisição vai direto para o nginx:

```text
$ curl -v localhost:8080/saude

* Connected to localhost (::1) port 8080
> GET /saude HTTP/1.1
> Host: localhost:8080
>
< HTTP/1.1 200 OK
< Server: nginx/1.29.1
< Content-Type: text/html; charset=UTF-8
< X-Powered-By: PHP/8.4.27
<
{"status":"ok","versao":"123abc"}
```

Aqui a versão é HTTP/1.1, porque não existe TLS e, portanto, não há ALPN para negociar o HTTP/2. O caminho foi este:

1. O Docker repassa a porta 8080 da minha máquina para a porta 80 do container do nginx.
2. O nginx compara `/saude` com os blocos `location` do `default.conf`. Ele cai no `location /`, e o `try_files $uri /index.php?$query_string` procura um arquivo `public/saude`. Como não existe, a requisição vai para `/index.php`.
3. O `/index.php` casa com o `location = /index.php`, a correspondência exata, que tem prioridade sobre o `location ~ \.php$`.
4. Esse bloco usa o `fastcgi_pass php:9000`. O nginx não fala HTTP com o PHP-FPM, ele fala FastCGI, e envia variáveis como `SCRIPT_FILENAME` e `REQUEST_URI`. É delas que nasce o `$_SERVER`.
5. Um worker do PHP-FPM executa o `public/index.php`, que lê o caminho e a `APP_VERSAO`, chama a classe `Resposta` e envia o status 200 e o JSON.

O cabeçalho `X-Powered-By: PHP/8.4.27` prova que o PHP participou. O log do container confirma: `"GET /index.php" 200`. Quando pedi um arquivo `.css` de teste, a resposta veio sem esse cabeçalho, porque o nginx entregou o arquivo direto do disco.