# 🏆 Subasta - Smart Contract

Trabajo Final - Módulo 2  
Autor: Jonathan Caillet Bois

---

## Descripción

Este contrato inteligente implementa una subasta en la red Scroll Sepolia. Permite a los usuarios ofertar (bid), realizar reembolsos parciales, manejar la extensión automática del tiempo de subasta y asegura un periodo de retiro exclusivo para los perdedores antes de liberar el balance al owner.

---

## Funcionalidades

### Constructor

Inicializa la subasta con los siguientes parámetros:
- **Duración** de la subasta (en segundos)
- **Valor inicial** de la subasta en wei

El incremento mínimo entre ofertas está fijado en 5%.  
La subasta se extiende automáticamente 10 minutos si una oferta válida se realiza en los últimos 10 minutos.
Los perdedores tienen 48hs para retirar sus ofertas perdedoras 
---

### Ofertar (`bid()`)

- Permite a los participantes realizar ofertas.
- Una oferta es válida si:
  - Es al menos un 5% mayor que la oferta actual.
  - Es igual o mayor al valor inicial si es la primera oferta.
  - Se realiza mientras la subasta está activa.
- Si la oferta se realiza en los últimos 10 minutos, la subasta se extiende 10 minutos más.

---

### Mostrar ganador (`getWinner()`)

Devuelve la dirección del ganador y el monto de la oferta ganadora.

---

### Mostrar ofertas (`getBids()`)

Devuelve la lista de todas las ofertas realizadas (direcciones y montos).

---

### Devolver depósitos a no ganadores (`refundLosers()`)

- Al finalizar la subasta, los participantes que no ganaron pueden retirar su depósito, descontando una comisión del 2%.
- Hay un periodo de **48 horas** tras el final de la subasta donde solo los perdedores pueden retirar sus fondos.

---

### Reembolso parcial (`withdrawExcess()`)

- Durante la subasta, los participantes pueden retirar el exceso depositado por encima de su última oferta válida.

---

### Retiro de comisión y premio (`withdrawCommission()`)

- El owner puede retirar el balance total del contrato **solo después de 48 horas** tras finalizar la subasta, permitiendo primero el retiro de los perdedores.
- Se emite un evento `CommissionWithdrawn` al retirar el balance.

---

### Instrucciones para reclamar el premio (`claimPrizeInstructions()`)

- El owner o el ganador pueden consultar instrucciones para reclamar el premio una vez finalizada la subasta.

---

## Variables Principales

- `owner`: Dueño del contrato.
- `auctionEndTime`: Timestamp de finalización de la subasta.
- `minIncrementPct`: Porcentaje mínimo de incremento entre ofertas (fijo en 5%).
- `minValueBid`: Valor inicial mínimo de la subasta.
- `extensionWindow`: Ventana para extensión automática (10 minutos).
- `extensionDuration`: Duración de la extensión (10 minutos).
- `losersRefundDeadline`: Timestamp hasta el cual los perdedores pueden retirar su depósito (48h tras el final).
- `highestBidder`: Dirección del mejor postor.
- `highestBid`: Monto de la mejor oferta.
- `bids`: Historial de todas las ofertas.
- `deposits`: Mapeo de depósitos por dirección.
- `lastBidAmount`: Última oferta válida por dirección.
- `ended`: Estado de la subasta.

---

## Eventos

- `NewBid(address bidder, uint256 amount, uint256 newEndTime)`: Nueva oferta válida.
- `AuctionEnded(address winner, uint256 amount)`: Subasta finalizada.
- `Withdrawal(address bidder, uint256 amount)`: Retiro de fondos (parcial o total).
- `CommissionWithdrawn(address owner, uint256 amount)`: Retiro de comisión/premio por el owner.

---

## Seguridad

- Uso de modificadores para controlar permisos y estados.
- Prevención de reentradas en retiros (patrón checks-effects-interactions).
- Validaciones estrictas en cada función.
- El contrato rechaza depósitos directos de ETH (solo se acepta a través de `bid()`).

---

## Despliegue

- Contrato desplegado y verificado en Scroll Sepolia.
- [URL del contrato en Scroll Sepolia] https://sepolia.etherscan.io/address/0x3d2994e3c0f63ab9269c5bd8449761e64f018fca

---

## Uso

1. **Ofertar:** Llama a `bid()` enviando ETH.
2. **Retirar exceso:** Llama a `withdrawExcess()` si depositaste más de tu última oferta.
3. **Finalizar subasta:** El owner puede llamar a `endAuction()`, o se finaliza automáticamente al vencer el tiempo.
4. **Retirar depósito (no ganadores):** Llama a `refundLosers()` tras finalizar la subasta y antes de las 48h.
5. **Retirar comisión/premio:** El owner puede llamar a `withdrawCommission()` solo después de las 48h tras finalizar la subasta.
6. **Reclamar premio:** El owner o el ganador pueden llamar a `claimPrizeInstructions()` para obtener instrucciones de entrega.

---

## Licencia

MIT# subasta
🧾 Trabajo Final - Módulo 2
