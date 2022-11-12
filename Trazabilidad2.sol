// Version de solidity del Smart Contract
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.16;

// Informacion del Smart Contract
// Nombre: Reserva
// Logica: Implementa subasta de productos entre varios participantes

// Declaracion del Smart Contract - Trazabilidad
contract Trazabilidad {
     // ----------- Variables (datos) -----------
    // Información de la Entrega
    enum  Status {ACCEPTED,READY,CLOK,RPOK,CLKO,RPKO,CANCEL,REALIZADA}
    struct Entrega {
        uint8  id;
        string  description;
        uint  price;
        uint256 timestamp;
        Status status;
        address cliente;
        address repartidor;
        
    }

    uint numEntregas;
    mapping (uint => Entrega) mapEntregas;

    address payable public owner;
    address payable public contractaddress;
    uint fondostotales = address(this).balance;

    //Evantos
    // ----------- Eventos (pueden ser emitidos por el Smart Contract) -----------
    event Msg(string _message);
    // ----------- Constructor -----------
    // Uso: Inicializa el Smart Contract - Reserva
    constructor() {
        
        // Inicializo el valor a las variables (datos)
       mapEntregas[numEntregas+1]=Entrega(
        1,
        "Entrega Producto fecha de entrega y localizacion",
        0.00001 ether,
        block.timestamp,
        Status.ACCEPTED,
        address(uint160(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2)),
        address(uint160(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db))
       );
        
        owner = payable(msg.sender);
        contractaddress = payable(address(this));
        
        // Se emite un Evento
        emit Msg("Entrega  Creada");
    }

    // ------------  Modificadore ------------
    // Modificador
    // Nombre: isRepartidor
    // Uso: Comprueba que es el repartidor de la entrega
    modifier isRepartidor {
        require(msg.sender ==  mapEntregas[numEntregas].repartidor,"No eres respartidor para firmar la llegada");
        _;
   }
    // Modificador
    // Nombre: isCliente
    // Uso: Comprueba que es el cleinte de la entrega
    modifier isCliente {
        require(msg.sender == mapEntregas[numEntregas].cliente,"No eres cliente para firmar la entrega");
        _;
   }
    // ------------ Funciones que modifican datos (set) ------------

    // Funcion
    // Nombre: repartidorFirmaSalida
    // Uso:    REaprtidor firma la salida al contrato si se cumplen las conciciones
    function repartidorFirmaSalida() public isRepartidor {
        
        mapEntregas[numEntregas].status = Status.READY;
        mapEntregas[numEntregas].timestamp = block.timestamp;
        emit Msg("La entrega a salido hacia su destino");
        
    }
    // Funcion
    // Nombre: repartidorFirmaLLlegada
    // Uso:    REaprtidor firma la llegada en contrato y se cumplen las conciciones
    function repartidorFirmaLlegada() public isRepartidor {
        mapEntregas[numEntregas].status = Status.RPOK;
        mapEntregas[numEntregas].timestamp = block.timestamp;
        emit Msg("El repartidor ha firmado la llega al destino");
    }
    // Funcion
    // Nombre: clienteFirmaRecepcion
    // Uso:    cliente firma la recepcion del producto y se cumplen las conciciones
    function clienteFirmaRecepcion() public isCliente {
        require(mapEntregas[numEntregas].status == Status.RPOK, "El repartidor no a llegado al destino");
        mapEntregas[numEntregas].status = Status.CLOK;
        mapEntregas[numEntregas].timestamp = block.timestamp;
        //TODO
        //Pagar todo el gas al vendedor y la parte proporcional al repartidor
        //Si el status es CLOK y RPOK a REALIZADA
         emit Msg("El Cliente a firmado la recepcion de Producto");
    }

    //Funcion cliente no firma recepcion se devuelve el dinero del contrato al vendedor menos la comison del repartidor

    //Funcion repartidor no firma llegada se le penaliza al repartidor y se devuelve el dinero al vendedor

    //Funcion crearEntrega y añadir al mapping comprobar que no existe

    //Funcion cancelar solo cliente o vendedor y no estado Ready XXOK se devuelve la pasta

    //crear Entrega y añadir al mapping
    


}