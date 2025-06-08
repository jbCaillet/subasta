/**
 *Submitted for verification at Etherscan.io on 2025-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title Subasta - Trabajo Modulo 2
 * @author jbCaillet
 */
contract Subasta {
    // EVENTOS 

    /// Registra oferta validad 
    event NewBid(address indexed bidder, uint256 amount, uint256 newEndTime);

    /// Aviso finalizacion subasta
    event AuctionEnded(address indexed winner, uint256 amount);

    /// Solicitud de retirar fondos
    event Withdrawal(address indexed bidder, uint256 amount);

    // Solicitud de retiro de comision
    event CommissionWithdrawn(address indexed owner, uint256 amount);

    // STRUCTS

    struct Bid {
        address bidder;
        uint256 amount;
    }

    address public owner;            // Dueño del contrato

    uint256 public auctionEndTime;   // Timestamp de finalización de la subasta
    uint256 public initialEndTime;   // Timestamp original (para la extensión de tiempo)
    uint256 public minIncrementPct;  // Porcentaje mínimo de incremento, fijo en 5%
    uint256 public extensionWindow;  // Ventana (en segundos) antes del final para extender (10 min)
    uint256 public extensionDuration;// Duración en segundos de la extensión (10 min)
    uint256 public minValueBid;      // Valor inicial de la subasta
    /*
    Funcion propia: Se agrega un tiempo luego de la subasta, donde bloquea el balance del contrato, para que los 
    perdedores retiren su dinero, luego de ese tiempo, el owner puede retirar el total del balance del contrato.
    */
    uint256 public losersRefundDeadline; 


    // Oferta ganadora
    address public highestBidder;
    uint256 public highestBid;

    // Listado de todas las ofertas (histórico)
    Bid[] public bids;

    // Mapeo de dirección a depósito total depositado
    mapping(address => uint256) public deposits;

    // Mapeo de dirección a última oferta válida
    mapping(address => uint256) public lastBidAmount;

    // Estado de la subasta
    bool public ended;

    //Modificadores
    modifier onlyOwner() {
        require(msg.sender == owner, "Solo el owner puede ejecutar");
        _;
    }

    modifier auctionActive() {
        require(block.timestamp < auctionEndTime, "La subasta no esta activa");
        require(!ended, "Subasta ya finalizada");
        _;
    }

    modifier auctionEnded() {
        require(block.timestamp >= auctionEndTime || ended, "La subasta sigue activa");
        _;
    }

    modifier afterRefundDeadline() {
        require(losersRefundDeadline > 0 && block.timestamp >= losersRefundDeadline, "Aun no paso el periodo de retiro para perdedores");
        _;
    }

    
    constructor(
        uint256 _biddingTime, // Duración de subaste en Segundos
        uint256 _minValueBid  //Valor inicial
    ) {
        require(_biddingTime > 0, "Duracion invalida");
        owner = msg.sender;
        initialEndTime = block.timestamp + _biddingTime;
        auctionEndTime = initialEndTime;
        minIncrementPct = 5; //Aumento del 5% como mínimo
        minValueBid = _minValueBid;
        extensionWindow = 10 minutes; // Ventana para extender 10 min 
        extensionDuration = 10 minutes; // Tiempo de extensión 10 min
    }

    // Funciones

    function bid() external payable auctionActive {
        require(msg.value > 0, "Debes enviar ETH");
        uint256 requiredMinBid = highestBid == 0
            ? minValueBid
            : highestBid + (highestBid * minIncrementPct) / 100;

        require(
            msg.value >= requiredMinBid,
            "La oferta debe superar en al menos el 5% la oferta actual"
        );

        // Registrar depósito y oferta
        deposits[msg.sender] += msg.value;
        lastBidAmount[msg.sender] = msg.value;

        // Registrar en histórico
        bids.push(Bid({bidder: msg.sender, amount: msg.value}));

        // Actualizar ganador
        highestBidder = msg.sender;
        highestBid = msg.value;

        // Extender subasta si estamos en la ventana de extensión
        if (auctionEndTime - block.timestamp <= extensionWindow) {
            auctionEndTime += extensionDuration;
        }

        emit NewBid(msg.sender, msg.value, auctionEndTime);
    }



    /**
     Permite retirar el exceso de depósito respecto a la última oferta (mientras la subasta está activa).
     */
    function withdrawExcess() external auctionActive {
        uint256 totalDeposit = deposits[msg.sender];
        uint256 lastBid = lastBidAmount[msg.sender];
        require(lastBid > 0, "No tienes ofertas activas");
        require(totalDeposit > lastBid, "No hay exceso para retirar");

        uint256 excess = totalDeposit - lastBid;
        deposits[msg.sender] = lastBid; // Solo deja la última oferta

        (bool sent, ) = payable(msg.sender).call{value: excess}("");
        require(sent, "No se pudo retirar el exceso");

        emit Withdrawal(msg.sender, excess);
    }

    /**
     Finaliza la subasta de manera anticipada (solo owner) o la marca como finalizada.
     */
    function endAuction() external {
        require(!ended, "Ya finalizada");
        require(
            msg.sender == owner || block.timestamp >= auctionEndTime,
            "Solo owner o tras finalizar"
        );
        ended = true;
        losersRefundDeadline = block.timestamp + 0 hours; // Ventana de 48h para refund de perdedores, lo dejo en 0, para que puedan probar el retiro en el momento
        emit AuctionEnded(highestBidder, highestBid);
    }

    /**
      Devuelve el depósito a los ofertantes no ganadores menos 2% de comisión.
     */
    function refundLosers() external auctionEnded {
        require(msg.sender != highestBidder, "El ganador no puede retirar");

        uint256 refund = deposits[msg.sender];
        uint256 bidAmount = lastBidAmount[msg.sender];

        require(refund > 0, "Nada para devolver");
        require(bidAmount > 0, "No participaste");

        // Descontar 2% de comisión
        uint256 commission = (bidAmount * 2) / 100;
        uint256 toReturn = refund - commission;

        // Prevenir re-entradas y futuras llamadas
        deposits[msg.sender] = 0;
        lastBidAmount[msg.sender] = 0;

        (bool sent, ) = payable(msg.sender).call{value: toReturn}(""); 
        require(sent, "No se pudo devolver el deposito");

        // Comisión queda en el contrato (puede ser retirada por el owner si se desea)
        emit Withdrawal(msg.sender, toReturn);
    }

    /**
      Devuelve el ganador y el valor de la oferta ganadora.
     */
    function getWinner() external view auctionEnded returns (address, uint256) {
        return (highestBidder, highestBid);
    }

    /**
      Devuelve la lista de todas las ofertas registradas.
     * @return array de direcciones y array de montos
     */
    function getBids() external view returns (address[] memory, uint256[] memory) {
        address[] memory bidders = new address[](bids.length);
        uint256[] memory amounts = new uint256[](bids.length);
        for (uint256 i = 0; i < bids.length; i++) {
            bidders[i] = bids[i].bidder;
            amounts[i] = bids[i].amount;
        }
        return (bidders, amounts);
    }

    /**
      Permite al owner retirar la comisión acumulada.
      Esta función se va a poder ejecutar luego de 48hs de finalizada la subasta, por lo que el saldo no retirado
      por los perdedores, será tomado como parte de la Ganancia.
     */
    function withdrawCommission() external onlyOwner auctionEnded afterRefundDeadline {
        uint256 contractBal = address(this).balance;
        require(contractBal > 0, "No hay fondos");
        (bool sent, ) = payable(owner).call{value: contractBal}("");
        require(sent, "No se pudo retirar la comision");
        emit CommissionWithdrawn(owner, contractBal);
    }

    //Getters

    function getCurrentTime() external view returns (uint256) {
        return block.timestamp;
    }

    function getDepositedAmount(address user) external view returns (uint256) {
        return deposits[user];
    }

    function getLastBid(address user) external view returns (uint256) {
        return lastBidAmount[user];
    }

    function bidsCount() external view returns (uint256) {
        return bids.length;
    }

    function claimPrizeInstructions() external view returns (string memory) {
    require(
        msg.sender == owner || msg.sender == highestBidder,
        "Solo el owner o el ganador pueden ejecutar"
    );
    require(ended, "La subasta debe haber finalizado");
    return "Para reclamar tu premio, envia un correo electronico a tp2@ethkipu.com con tus datos de envio.";
    }

    receive() external payable {
        revert("Utiliza bid()");
    }
}