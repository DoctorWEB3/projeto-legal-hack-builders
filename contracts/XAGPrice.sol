// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { FunctionsClient } from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import { FunctionsRequest } from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract XAGPrice is FunctionsClient {
    using FunctionsRequest for FunctionsRequest.Request;
    using Strings for uint256;

    address public admin;

    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;

    error RequestIdMismatch();

    uint256 public lastXAGPriceUpdated;
    bytes32 public donId = 0x66756e2d706f6c79676f6e2d616d6f792d310000000000000000000000000000;
    address public router = 0xC22a79eBA640940ABB6dF0f7982cc119578E11De;
    uint32 gasLimit = 300000;
    //API Key metal XAG --> 0efe8b1167bc708f7dbb5cad3fc6c4e7
    //No plano gratuito o delay da cotação é diário


    string public sourceIPCA = 
        'const timestamp=args[0],apiKey=args[1];if(!timestamp||!apiKey){throw new Error("E necessario fornecer o timestamp e a chave da API como argumentos.")}console.log("Timestamp fornecido:",timestamp);const url=`https://api.metalpriceapi.com/v1/latest?api_key=${apiKey}&base=USD&currencies=XAG`;try{const response=await Functions.makeHttpRequest({url:url,method:"GET"});console.log("Resposta completa da API:",JSON.stringify(response));if(response.error){throw new Error(`Erro HTTP: ${JSON.stringify(response.error)}`)}const data=response.data;if(!data||!data.rates||data.rates["XAG"]===undefined){throw new Error("Cotacao XAG nao encontrada na resposta.")}const price=data.rates["USDXAG"];console.log("Preco da prata (XAG):",price);const formatted=Math.round(price*100);return Functions.encodeUint256(formatted)}catch(err){console.error("Erro no processamento:",err.message||err);return Functions.encodeUint256(0)}';


    event XAGPriceUpdated(bytes32 indexed requestId, uint256 indexed lastXAGPriceUpdated, bytes s_lastResponse, bytes s_lastError);

    constructor() FunctionsClient(router) {
        admin = msg.sender;
    }


    function sendRequestUSDXAG(uint64 subscriptionId, uint256 timestampStart, string memory apiKey) external returns (bytes32 requestId) {
        require(msg.sender == admin, "You're not the admin");
        string[] memory args = new string[](2);
        args[0] = Strings.toString(timestampStart);
        args[1] = apiKey;

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(sourceIPCA);
        req.setArgs(args);

        s_lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donId
        );

        return s_lastRequestId;
    }

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (s_lastRequestId != requestId) {
            revert RequestIdMismatch();
        }

        s_lastResponse = response;
        lastXAGPriceUpdated = abi.decode(response, (uint256));
        s_lastError = err;

        emit XAGPriceUpdated(requestId, lastXAGPriceUpdated, s_lastResponse, s_lastError);

    }

    function getXAGPriceUpdated() external view returns (uint256) {
        return lastXAGPriceUpdated;
    }
}