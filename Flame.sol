// Version de solidity del Smart Contract
// SPDX-License-Identifier: UNLICENSED

import './RandomValidators.sol';

pragma solidity ^0.8.16;
// Informacion del Smart Contract
// Nombre: Reserva
// Logica: Implementa subasta de productos entre varios participantes

// Declaracion del Smart Contract - Auction
contract Flame {

    // ----------- Variables (datos) -----------
    // Información del Post publicado
    enum  StatusPost {CREADO,LECTOR,JUICIO}

    struct PostCreador {
        address payable creadorAddress;
        uint256 timestamp;
        StatusPost statusPost;
        address payable lectorAddress;
        uint votosPos;
        uint votosNeg;
        mapping (address => address) mapValidatorsPost;
        address[] addressVotosPos;
        address[] addressVotosNeg;
    }
    //Uri creador -> address 
    mapping (string => PostCreador) mapUriCreador;
    //Variables validadores
    struct Validadores {
        bool isValidator;
        uint deposito;
    }
    mapping (address => Validadores) mapAddressValidators;

    //Propietario y actores en el reparto
    address payable owner;
    address payable contractaddress;
    uint fondostotales = address(this).balance;

    //Constantes Status
    string CREADO = "CREADO";
    string REFUTADO = "REFUTADO";
    string JUICIO = "JUICIO";

    uint private fijoJuicio = 3 ether;
    uint private fijoPublicacion = 10 ether;
    uint private fijoDepositoValidador = 100 ether;
    uint private totalValidadores = 0;

    //Variable Contrato Random
    RandomValidators randomValidators;  
    //se meten en un array de numeros para coincidier en los indices
    uint[] validadoresElejidos;   

    //Eventos
    // ----------- Eventos (pueden ser emitidos por el Smart Contract) -----------
    event Msg(string _message);

    // ----------- Constructor -----------
    // Uso: Inicializa el Smart Contract - Inicio de Ruta
    constructor() {
        
        // Inicializo el valor a las variables (datos)
        owner = payable(msg.sender);
        contractaddress = payable(address(this));
        //instancio el contatro RondomValidatros
        randomValidators = new RandomValidators;
      
        // Se emite un Evento
        emit Msg("Contrato Flame Desplegado");
    }

    // ------------  Modificadores ------------
    // Modificador
    // Nombre: isOwner
    // Uso: Comprueba que es el owner del contrato
    modifier isOwner {
        require(msg.sender == owner,"No eres creador del contrato");
        _;
   }
    // Modificador
    // Nombre: isNot0x000000
    // Uso: Comprueba que es 0x000000
    modifier isNot0x000000 (address addr) {
        require(addr != address(0), "Not valid address");
        _;
   }
    // Modificador
    // Nombre: is10Flms
    // Uso: Comprueba que paga 10 flms
    modifier is10Flms () {
       require(msg.value == 10 ether," Introduce la cantidad de 10 Flm");
        _;
   }

    // Modificador
    // Nombre: is10Flms
    // Uso: Comprueba que paga 10 flms
    modifier isCreateUri (string storage _uri) {
       require(mapUriCreador[_uri].statusPost == StatusPost.CREADO, " No puedes avisar de este articulo");
        _;
   }

    function publicar(string calldata _uri) public payable is10Flms {
        //Varifica que la noticia no esta creada
        require(mapUriCreador[_uri].creadorAddress != address(0x0), " La notica no es correcta ");
        //Pago al repartidor el precio
        mapUriCreador[_uri].creadorAddress = payable(msg.sender);
        mapUriCreador[_uri].timestamp = block.timestamp;
        mapUriCreador[_uri].statusPost = StatusPost.CREADO;   
        payable(msg.sender).transfer(fijoPublicacion);
           
    }

    function avisar(string calldata _uri) public payable is10Flms() {
        require(mapUriCreador[_uri].creadorAddress != address(0x0), " La notica no es correcta ");
        require(mapUriCreador[_uri].statusPost != StatusPost.CREADO, " La noticia no esta en el estado adecuado"); 
        mapUriCreador[_uri].lectorAddress = payable(msg.sender);
        mapUriCreador[_uri].statusPost = StatusPost.LECTOR;
        mapUriCreador[_uri].votoNeg = 0;
        mapUriCreador[_uri].votoPos = 0; 
        //Calcula los validadores
        randomValidators.selectOlddNumbers(totalValidadores);

        payable(msg.sender).transfer(fijoPublicacion);
       
    }


    // Funcion
    // Nombre: pánico
    // Uso: Se devuelve el dinero del contrato al owner
    function panico() public isOwner(){
        
        owner.transfer(address(this).balance);
        emit Msg("Funcion de panico realizada se devuelven los fondos del Contrato al owner");
    }

// add validator to list validators
    function addValidator() public {
        require(msg.value == 100 ether," Introduce la cantidad de 100 Flm para ser validador");
        mapAddressValidators[msg.sender].deposito = fijoDepositoValidador;
        mapAddressValidators[msg.sender].isValidator = true;
        totalValidadores = totalValidadores + 1;
        payable(msg.sender).transfer(fijoDepositoValidador);
    }
//delete to list validators
    function removeValidator() public {
        //Si el el validadoe que entra tiene 0 o menos en depositos de echamos de la lista de validadores
        if(mapAddressValidators[msg.sender].deposito <= 0){
            mapAddressValidators[msg.sender].isValidator = false;
            totalValidadores = totalValidadores - 1;  
        }
        //Validamos que es validador para poder recuperar su deposito
        require(mapAddressValidators[msg.sender] != address(0x0), "Not valid address in validators");
        uint devolucion = mapAddressValidators[msg.sender].deposito;
        mapAddressValidators[msg.sender].isValidator = false;
        totalValidadores = totalValidadores - 1;
        payable(contractaddress).transfer(devolucion);
        
    }

//Tiene lugar el juicio
    function juicio (string calldata _uri, bool _voto) public {
        //Valida que la noticia existe
        require(mapUriCreador[_uri].creadorAddress != address(0x0), " La notica no es correcta ");
        //Valida que la notica esta en Juicio
        require(mapUriCreador[_uri].statusPost == StatusPost.JUICIO, " La notica no esta en juicio ");
        //valida que el validador esta activo
        require(mapAddressValidators[msg.sender].isValidator != false, " Validador no activo ");
        //valida que el validador existe
        require(mapAddressValidators[msg.sender] != address(0x0), "Not valid address in validators");
        //valdia que no ha validado la noticia
        require(mapUriCreador[_uri][msg.sender] != address(0x0), "Ya valido la noticia" );
        //resolver validadores elejidos aleatoriamente
        validadoresElejidos = randomValidators.selectOlddNumbers(11);


        mapUriCreador[_uri][msg.sender] = msg.sender; 

        if(_voto){
            mapUriCreador[_uri].addressVotosPos.push(msg.sender);
            mapUriCreador[_uri].votosPos++; 
        }else{
            mapUriCreador[_uri].addressVotosNeg.push(msg.sender);
            mapUriCreador[_uri].votosNeg++;
        }
        
    }

    function calcularReparto(string calldata _uri) public {
        require(mapUriCreador[_uri].creadorAddress != address(0x0), " La notica no es correcta ");
        uint votoPos = mapUriCreador[_uri].votosPos;
        uint votoNeg = mapUriCreador[_uri].votosNeg;
        if(votoPos > votoNeg){
            mapUriVotoAddress[_uri][_voto]
            //Gana el creador de la noticia

        }else if(votoNeg > votoPos){
            //Gana el lector
        }

        uint repartovalidadores = totalValidadores / 3;

        //TODO PAgar 3 a los validadores solo si la respuesta es correcta
    }


}