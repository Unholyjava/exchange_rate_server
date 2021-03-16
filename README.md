# exchange_rate_server

This application return exchange rates from PrivatBank database 
or cache ets table in the current server, 
depending on time (in this case data save for 60 second in the ets table,
requests in this period are into ets, 
then after 60 second request is into PrivatBank database and so on).
Response is in XML-view.

To try this application and have right view of XML-output,
you need any internet browser or command line with XML-output support.

To build the application use the following command:
$ make

To run the application use the following command:
$ make debug

# example output using browser

http://localhost:8080/api/exchange_rate_server

<exchangerates>
    <row>
        <exchangerate ccy="USD" base_ccy="UAH" buy="27.45000" sale="27.86000"/>
    </row>
    <row>
        <exchangerate ccy="EUR" base_ccy="UAH" buy="32.65000" sale="33.25000"/>
    </row>
    <row>
        <exchangerate ccy="RUR" base_ccy="UAH" buy="0.36000" sale="0.39500"/>
    </row>
    <row>
        <exchangerate ccy="BTC" base_ccy="USD" buy="53462.1794" sale="59089.7772"/>
    </row>
</exchangerates>

# example output using command line without XML-output support

$ curl -i -H "Content-Type: text/xml; charset=utf-8" http://http://localhost:8080/api/exchange_rate_server

HTTP/1.1 200 OK
content-length: 417
content-type: text/xml; charset=utf-8
date: Tue, 16 Mar 2021 21:00:25 GMT
server: Cowboy

<exchangerates><row><exchangerate ccy="USD" base_ccy="UAH" buy="27.45000" sale="27.86000"/>
</row><row><exchangerate ccy="EUR" base_ccy="UAH" buy="32.65000" sale="33.25000"/>
</row><row><exchangerate ccy="RUR" base_ccy="UAH" buy="0.36000" sale="0.39500"/>
</row><row><exchangerate ccy="BTC" base_ccy="USD" buy="53462.1794" sale="59089.7772"/>
</row></exchangerates>
