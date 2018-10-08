
ContractPen Work Server
=======================

Client programs which are https://github.com/contractpendev/contractpen_node_client will subscribe to this work server to wait for work orders and execute those work order. It is expected that hundreds of clients will connect to the server to await work orders. 

To compile coffeescript

npm run compile

ContractPen
-----------

ContractPen is a simple web user interface designed to allow people eventually to deploy legal contracts to the blockchain. The current goal is to integrate ContractPen.com with the Accord Project https://www.accordproject.org/ as this project allows legal contract clauses to execute on the blockchain.

Open Source
-----------

Although ContractPen.com is currently closed source, it may become open source in the future. So in that spirit it is useful to encourage open source around the ContractPen API's and integration with other open source projects such as Accord Project.

I encourage you to build open source software around the legaltech software and integration with ContractPen data API's and to learn the Accord Project.

Required software
-----------------

1. NodeJS v10.7.0 is the version I am using.

2. Coffeescript as the coffee command https://coffeescript.org/

Libraries used
--------------

Some libraries are in use to try to help development within NodeJS.

Dependency injection

https://github.com/jeffijoe/awilix

Graph library which is not really used in this project but is added

https://github.com/dagrejs/graphlib/wiki

Redis client

https://github.com/NodeRedis/node_redis

