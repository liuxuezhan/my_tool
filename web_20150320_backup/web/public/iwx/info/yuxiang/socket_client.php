<?php
/**
 * @author linruirong@tapenjoy.com
 * @copyright www.tapenjoy.com
 */

include_once('socket_api.php');
class SocketClient {
    const SOCKET_TIMEOUT        = 3;
    const MAX_BUFFER_SIZE       = 1024;
    
    public $host; // 通信地址
    public $port; // 通信端口
    private $socket = null;
    
    private $logger                        = NULL;
    
    public function __construct($host = null, $port = null)
    {
        $this->setIpPort($host, $port);
    }
    
    public function setLogger($logger)
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
    
    public function setIpPort( $ip, $port ){
        $this->host = $ip;
        $this->port = $port;
    }
    
    /**
     * 发起socket请求
     *
     * @param string $action
     * @param array $data
     * @return array
     */
    public function rpc($apiId,$data)
    {
        $fp = @fsockopen("tcp://{$this->host}", $this->port);
        if(!$fp){
            return array('result'=>10001, 'errorMsg'=>'连接游戏服务器失败');
        }
        @stream_set_timeout($fp, self::SOCKET_TIMEOUT) ; //超时时间 3秒

        $binApiId = $this->decToBinStr($apiId, 2); //2字节，协议编号
        $strJson = $this->decodeUnicode(json_encode($data));
        $lenJson = strlen($strJson);
        
//      _debug("socket client json: \n".$strJson);
//      _debug("socket client json len : ".$lenJson);
        
        $binLenJson = $this->decToBinStr($lenJson,2);  // 2字节，json串总长度
        $str = $binApiId.$binLenJson.$strJson;
        $str = $this->decToBinStr($lenJson+8).$str; // 4+2+2 =8 头部4字节 记录包总长度（包括头部）
        $write = @fwrite($fp, $str);
        
        if (false===$write) { 
            @fclose($fp);
            return array('result'=>10002, 'errorMsg'=>'发送消息到游戏服务器失败'); 
        }
        
        $returnDataLen = $this->binStrToDec(@fread($fp, 4),4); //包头4个字节，记录着其后包体的数据长度
        $retApiId = $this->binStrToDec(@fread($fp,2),2); // 2字节，协议编号
        $lenReturnJson = $this->binStrToDec(@fread($fp,2),2); // 2字节，服务端返回json串总长度
        $returnData = @fread($fp, $lenReturnJson);
        
        $status = stream_get_meta_data( $fp ) ;
        if($status['timed_out']){
            @fclose($fp);
            return array('result'=>10003, 'errorMsg'=>'等待服务端返回数据超时');
        }
        
        $serverRet = json_decode($returnData, true);
//      _debug("server return json: \n". $returnData. "\n\n after decode:\n");
//      _debug($serverRet);
        
        if(!is_array($serverRet) || !array_key_exists('result', $serverRet) ){
            @fclose($fp);
            return array('result'=>10004, 'errorMsg'=>'服务器返回数据格式不正确');
        }
        @fclose($fp);
        
        return $serverRet;
    }
    
    public function idipCall($apiId, $data)
    {
        $fp = fsockopen("tcp://{$this->host}", $this->port);
        if(!$fp){
            return array('result'=>10001, 'errorMsg'=>'连接游戏服务器失败');
        }
        $this->debug($fp);
        
        stream_set_timeout($fp, self::SOCKET_TIMEOUT) ; //超时时间 3秒
        
        $binApiId = $this->decToBinStr($apiId, 2); //2字节，协议编号
        $this->debug($data);
        $strJson = $this->decodeUnicode(json_encode($data));
        $this->debug($strJson);
        $lenJson = strlen($strJson);
        
        //      _debug("socket client json: \n".$strJson);
        //      _debug("socket client json len : ".$lenJson);
        
        $binLenJson = $this->decToBinStr($lenJson, 2);  // 2字节，json串总长度
        $str = $binApiId . $binLenJson . $strJson;
        $str = $this->decToBinStr($lenJson+8) . $str; // 4+2+2 =8 头部4字节 记录包总长度（包括头部）
        $write = @fwrite($fp, $str);
        
        if (false===$write) {
            @fclose($fp);
            return array('result'=>10002, 'errorMsg'=>'发送消息到游戏服务器失败');
        }
        
        $returnDataLen = $this->binStrToDec(@fread($fp, 4),4); //包头4个字节，记录着其后包体的数据长度
        $retApiId = $this->binStrToDec(@fread($fp,2),2); // 2字节，协议编号
        $lenReturnJson = $this->binStrToDec(@fread($fp,2),2); // 2字节，服务端返回json串总长度
        $returnData = @fread($fp,$lenReturnJson);
        
        $status = stream_get_meta_data( $fp ) ;
        if($status['timed_out']){
            @fclose($fp);
            return array('result'=>10003, 'errorMsg'=>'等待服务端返回数据超时');
        }
        
        $serverRet = json_decode($returnData,true);
        //      _debug("server return json: \n". $returnData. "\n\n after decode:\n");
        //      _debug($serverRet);
        
        @fclose($fp);
        
        return $serverRet;
    }
    
    
    /**
     * 把二进制转换为十进制
     *
     * @param binary $binStr
     * @return int
     */
    private function binStrToDec($binStr,$byte=4){
        $rs = '';
        if ($binStr) {
            if (4==$byte) {
                $arr = unpack('I',$binStr);
            }elseif (2==$byte) {
                $arr = unpack('v',$binStr);
            }
            $rs = is_array($arr) ? array_shift($arr) : '';
        }
        return $rs;
    }
    
    /**
     * 十进制转换为二进制
     *
     * @param int $num
     * @param int $byte 转换后所占字节数
     * @return binary string
     */
    private function decToBinStr($num, $byte=4){
        if ($num) {
            if (4==$byte) {
                $str = pack('I', $num);
            }elseif (2==$byte) {
                $str = pack('v', $num);
            }
        }
        return $str;
    }
    
    
    public function decodeUnicode($str)
    {
        return preg_replace_callback('/\\\\u([0-9a-f]{4})/i',
            create_function(
                '$matches',
                'return mb_convert_encoding(pack("H*", $matches[1]), "UTF-8", "UCS-2BE");'
            ),
            $str);
    }
    
}

