<?php
/**
 * @author linruirong@tapenjoy.com
 * @copyright www.tapenjoy.com
 */
include_once('socket_client.php');

class ServerApi {
    
    const GPT_GM                          = 0xA004;
    const YUN_CHANGE_TO_GOLD              = 0xA103;
    const GPT_IDIP_GM                     = 0xA105;
    const PT_GET_QQ_POWER                 = 0xA106;
    
    private $logger                        = NULL;
    
    public function __construct($logger = NULL)
    {
        $this->logger = $logger;
    }
    
    public function debug($msg)
    {
        if (!empty($this->logger)) {
            $this->logger->debug($msg);
        }
    }
    
    public function err($msg)
    {
        if (!empty($this->logger)) {
            $this->logger->err($msg);
        }
    }
    
    public function info($msg)
    {
        if (!empty($this->logger)) {
            $this->logger->info($msg);
        }
    }

    ////////////*发送GM指令*////////////////////////
    public function sendGmCmd( $ip, $port, $gmStr, $apiId = ServerApi::GPT_GM )
    {
        $gmStr = trim(stripslashes( $gmStr ));
        
        if( empty( $gmStr ) ){
            $msg = "Operation failed! GM msg cannot be null!";
            $retAry = array( 'ret' => 0, 'msg' => $msg, 'data' => null );
            return $retAry;
        }
        
        $socketData = array(
            'cmd' => $gmStr,
        );
        
        $socket = new SocketClient($ip, $port);
        $ret = $socket->rpc($apiId, $socketData);
        
        $bSucc = 1;
        if (1 == $ret['result']) {
            $msg = null;
            $data = $ret['data'];
            $bSucc = 1;
        }else {
            $msg = $ret['errorMsg'];
            $data = null;
            $bSucc = 0;
        }
        
        $retAry = array( 'ret' => $bSucc, 'msg' => $msg,  'data' => $data );
        
        return $retAry;
    }

    ////////////*发送通用指令*////////////////////////
    public function sendCommonCmd( $ip, $port, $data, $apiId = ServerApi::YUN_CHANGE_TO_GOLD )
    {
        $socket = new SocketClient($ip, $port);
        $ret = $socket->rpc($apiId, $data);
        return $ret;
    }
    
    ////////////*发送IDIP指令*///////////////////////
    public function sendIdipCmd($ip, $port, $data, $apiId = ServerApi::GPT_IDIP_GM)
    {
        $this->debug('start sendIdipCmd: ' . microtime(true));
        $socket = new SocketClient($ip, $port);
        $socket->setLogger($this->logger);
        $this->debug('start socket->idipCall: ' . microtime(true));
        $ret = $socket->idipCall($apiId, $data);
        $this->debug('return: ' . microtime(true));
        return $ret;
    }
}

