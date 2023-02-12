// Version de solidity del Smart Contract
// SPDX-License-Identifier: UNLICENSED

import './RandomValidators.sol';

pragma solidity ^0.8.16;
// Informacion del Smart Contract
// Nombre: Flame
// Logica: Logica Flame
// Declaracion del Smart Contract - Flame
contract Flame {

    // ----------- Variables (datos) -----------
    // Información del Post publicado
    enum  StatusPost {CREADO,LECTOR,JUICIO,JUZGADO}

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
    address[] validadoresActivos;
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
        randomValidators = new RandomValidators();
      
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
        mapUriCreador[_uri].votosNeg = 0;
        mapUriCreador[_uri].votosPos = 0; 
        //Calcula los validadores
        validadoresElejidos = randomValidators.selectOlddNumbers(totalValidadores);
       
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
        validadoresActivos.push(msg.sender);
        payable(msg.sender).transfer(fijoDepositoValidador);
    }
//delete to list validators
    function removeValidator() public {
        //Si el el validadoe que entra tiene 0 o menos en depositos de echamos de la lista de validadores
        if(mapAddressValidators[msg.sender].deposito <= 0){
            mapAddressValidators[msg.sender].isValidator = false;
            totalValidadores = totalValidadores - 1; 
            for (uint i = 0 ; i < validadoresActivos.length; i++){
            if(validadoresActivos[i] == msg.sender){
                delete validadoresActivos[i];
                i == 0;
            }
        } 
        }
        //Validamos que es validador para poder recuperar su deposito
        require(mapAddressValidators[msg.sender].deposito != 0, "Not valid address in validators");
        uint devolucion = mapAddressValidators[msg.sender].deposito;
        mapAddressValidators[msg.sender].isValidator = false;
        totalValidadores = totalValidadores - 1;
        for (uint i = 0 ; i < validadoresActivos.length; i++){
            if(validadoresActivos[i] == msg.sender){
                delete validadoresActivos[i];
                i == 0;
            }
        }
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
        bool elejido = false;
        for(uint i = 0; i < validadoresElejidos.length; i++){
            for (uint j = 0; j < validadoresActivos.length; j++){
                if(validadoresActivos[i] == msg.sender){
                    elejido = true;
                } 
            }
        }
        require(elejido == true,"No has sido elejido para la validacone de esta notica");
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
        if (votoPos == 0){

        }else if (votoNeg == 0){

        }else if(votoPos > votoNeg){
            //Ganan el creador
            //Reparto de 3 flms para cada validador
            uint total = mapUriCreador[_uri].addressVotosPos.length / 3;
            for(uint i = 0 ; i < mapUriCreador[_uri].addressVotosPos.length; i++){
                   address val = mapUriCreador[_uri].addressVotosPos[i];
                   mapAddressValidators[val].deposito = mapAddressValidators[val].deposito + total;
            }
            
            //Calculo perdidas del lector
            uint calculoLector = (10 - (fijoPublicacion/10));
            mapUriCreador[_uri].lectorAddress.transfer(calculoLector);
            //Calculo ganancias del creador
            uint calculoCreador = (10 + (fijoPublicacion/10));
            mapUriCreador[_uri].lectorAddress.transfer(calculoLector);
        }else if(votoNeg > votoPos){
            //Gana el lector
             //Reparto de 3 flms para cada validador
            uint total = mapUriCreador[_uri].addressVotosNeg.length / 3;
            for(uint i = 0 ; i < mapUriCreador[_uri].addressVotosNeg.length; i++){
                   address val = mapUriCreador[_uri].addressVotosNeg[i];
                   mapAddressValidators[val].deposito = mapAddressValidators[val].deposito + total;
            }
            
            //Calculo ganacias del lector
            uint calculoLector = (10 + (fijoPublicacion/10));
            mapUriCreador[_uri].lectorAddress.transfer(calculoLector);
            //Calculo perdidas del creador
            uint calculoCreador = (10 - (fijoPublicacion/10));
            mapUriCreador[_uri].lectorAddress.transfer(calculoLector);
        }
        mapUriCreador[_uri].statusPost = StatusPost.JUZGADO;
       
    }


}