// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./SafeMath.sol";


contract Loteria {

  using SafeMath for uint;


  // direcciones
  address public owner = msg.sender;

  // instancia del contrato token
  ERC20Basic private token = new ERC20Basic(1000);

  // precio token en weis
  uint public precioToken = 100;
  
  
  // ---------------- TOKEN ----------------

  event ComprandoTokens (uint, address);


  modifier onlyOwner() {
    // requiere que la direccion del ejecutor de la funcion sea igual al owner del contrato
    require(msg.sender == owner, 'No tienes permiso para acceder a esta funcion');
    _;
  }


  // establecer el precio de los tokens en weis
  function precioTokens(uint _numTokens) internal view returns (uint) {
    return _numTokens.mul(precioToken);
  }

  // generar mas tokens por la loteria
  function generarTokens(uint _numTokens) public onlyOwner() {
    token.increaseTotalSupply(_numTokens);
  }

  // comprar tokens para comprar tickets para la loteria
  function comprarTokens(uint _numTokens) public payable {
    // calcular el coste de los tokens
    uint coste = precioTokens(_numTokens);

    // se requiere que el valor de weis pagados sea equivalente al coste
    require(msg.value >= coste, "Compra menos tokens o paga con mas weis");

    // transferencia de la diferencia
    payable(msg.sender).transfer(msg.value - coste);

    // filtro para evaluar los tokens a comprar con los tokens disponibles
    require(_numTokens <= tokensDisponibles(), "Compra un numero de tokens adecuado");

    // transferencia de tokens al comprador
    token.transfer(msg.sender, _numTokens);

    // emitir el evento de compra tokens
    emit ComprandoTokens(_numTokens, msg.sender);
  }

  // balance de tokens en el contrato de loteria
  function tokensDisponibles() public view returns (uint) {
    return token.balanceOf(address(this));
  }

  // obtener el balance de tokens acumulados en el pozo
  function verPozoAcumulado() public view returns (uint) {
    return token.balanceOf(owner);
  }

  // balance de tokens de una persona
  function misTokens() public view returns (uint) {
    return token.balanceOf(msg.sender);
  }


  // ---------------- LOTERIA ----------------

  // precio del boleto en tokens
  uint public precioBoleto = 5;

  // boletos generados
  uint[] boletosComprados;

  // relacion entre la persona que compra los boletos y los numeros de los boletos
  mapping(address => uint[]) personaBoletos;

  // numero aleatorio
  uint randNonce = 0;

  // relacion necesaria para identificar al ganador
  mapping(uint => address) boletoPersona;


  //eventos
  event BoletoComprado(uint, address); // evento cuando se compra un boleto
  event BoletoGanador(uint); // evento del ganador


 // funcion para comprar boletos de loteria
  function comprarBoletos(uint _boletos) public {
    // precio total de los boletos a comprar
    uint coste = _boletos.mul(precioBoleto);

    // filtrado de los tokens a pagar
    require(coste <= misTokens(), "Necesitas comprar mas tokens");

    // el cliente paga la transaccion en token
    token.transferFromTo(msg.sender, owner, coste);

    for (uint i = 0; i < _boletos; i++) {
      // generamos un valor aleatorio entre 0 - 9999
      uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 1000;

      // incrementamos el nonce
      randNonce++;

      // almacenamos los datos de los boletos
      personaBoletos[msg.sender].push(random);

      // numero de boleto comprado
      boletosComprados.push(random);

      // asignacion del ADN del boleto para tener un ganador
      boletoPersona[random] = msg.sender;

      // emision del evento
      emit BoletoComprado(random, msg.sender);
    }
  }

  // visualizar el numero de boletos de una persona
  function misBoletos() public view returns (uint[] memory) {
    return personaBoletos[msg.sender];
  }

  // funcion para generar un ganador e ingresarle los tokens
  function generarGanador() public onlyOwner() {
    // declaracion de la longitud del array de boletos comprados
    uint boletos = boletosComprados.length;

    // debe haber boletos comprados para generar un ganador
    require(boletos > 0, "No hay boletos comprados");

    // aleatoriamente elijo un numero entre: 0 y longitud
    uint eleccion = boletosComprados[uint(uint(keccak256(abi.encodePacked(block.timestamp))) % boletos)];

    // recuperar la direccion del ganador y le enviamos los tokens del premio
    token.transferFromTo(msg.sender, boletoPersona[eleccion], verPozoAcumulado());

    // emision del evento del ganador
    emit BoletoGanador(eleccion);
  }

  // 
  function a() public {
    payable(msg.sender).transfer();
  }

}
