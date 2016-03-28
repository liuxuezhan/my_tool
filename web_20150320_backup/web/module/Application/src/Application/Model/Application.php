<?php
namespace Application\Model;

//use Zend\Db\TableGateway\AbstractTableGateway;

use Zend\ServiceManager\ServiceLocatorAwareInterface;
use Zend\ServiceManager\ServiceLocatorInterface;

class Application implements ServiceLocatorAwareInterface
{
    const CX_CODE_SUCCESS           = 1;
    const CX_CODE_FAILED            = 0;
    
    const CX_SIG_FRIENDS_KEY        = CX_SIG_FRIENDS_KEY;
    const CX_CERTIFY_KEY            = CX_SIG_CERTIFY_KEY;
    const CX_PAY_KEY                = CX_SIG_PAY_KEY;
    const CX_SIG_RELATION_KEY       = CX_SIG_RELATION_KEY;
    const CX_RETURN_SUCCESS         = 0;
    const CX_RETURN_FAILED          = 2;
    
    //MSDK return code(0: success, other: failed)
    const TX_CODE_SUCCESS           = 0;
    
    //MSDK定义的平台类型
    const ePlatform_Weixin 	        = TX_PLATFORM_WEIXIN;
    const ePlatform_QQ              = TX_PLATFORM_QQ;
    const ePlatform_WTLogin	        = TX_PLATFORM_WTLOGIN;
    const ePlatform_QQHall          = TX_PLATFORM_QQHALL;
    const ePlatform_Guest           = TX_PLATFORM_GUEST;
    
    //OS定义
    const OS_IOS                    = MSDK_OS_IOS;
    const OS_ANDROID                = MSDK_OS_ANDROID;
    
    public $appid;
    public $appkey;
    public $openid;
    public $openkey;
    public $platform;
    public $os;
    public $zoneid;
    public $host;
    public $uri;
    public $url;
    public $protocol;
    
    public $ePlatformList       = array(
        self::ePlatform_Weixin      => 'Weixin',
        self::ePlatform_QQ          => 'QQ',
        self::ePlatform_WTLogin     => 'WTLogin',
        self::ePlatform_QQHall      => 'QQHall',
        self::ePlatform_Guest       => 'Guest',
    );
    public $osList              = array(
        self::OS_IOS                => 'ios',
        self::OS_ANDROID            => 'android',
    );
    
    public $validationErrors    = array();
    
    protected $serviceLocater;
    
    public function __construct()
    {
        $this->appid    = null;
        $this->appkey   = null;
        $this->openid   = null;
        $this->openkey  = null;
        $this->platform = null;
        $this->os       = null;
        $this->zoneid   = null;
        $this->host     = null;
        $this->uri      = null;
        $this->url      = null;
        $this->protocol = null;
    }
    
    public function setServiceLocator(ServiceLocatorInterface $serviceLocator)
    {
        $this->serviceLocater = $serviceLocator;
    }
    
    public function getServiceLocator()
    {
        return $this->serviceLocater;
    }
    
    public function setAppId($appid)
    {
        $this->appid = $appid;
    }
    
    public function setAppKey($appkey)
    {
        $this->appkey = $appkey;
    }
    
    public function setOpenId($openid)
    {
        $this->openid = $openid;
    }
    
    public function setOpenKey($openkey)
    {
        $this->openkey = $openkey;
    }
    
    public function setPlatform($platform)
    {
        $this->platform = $platform;
    }
    
    public function setOs($os)
    {
        $this->os = $os;
    }
    
    public function setZoneId($zoneid)
    {
        $this->zoneid = $zoneid;
    }
    
    //Need to be overrided
    public function validate($data)
    {
        $ret = true;
        if (!isset($data['platform']) || !array_key_exists($data['platform'], $this->ePlatformList)) {
            $this->validationErrors[] = 'platform field is not in the platform list';
            $ret = false;
        }
        if (!isset($data['os']) || !array_key_exists($data['os'], $this->osList)) {
            $this->validationErrors[] = 'os field is not in the os list';
            $ret = false;
        } 
        
        return $ret;
    }
    
    //Maybe need to be overrided
    public function store($data, $is_validate = true)
    {
        if (($is_validate && $this->validate($data)) || !$is_validate) {
            $this->setPlatform($data['platform']);
            $this->setOs($data['os']);
            $this->setOpenId($data['open_id']);
            $this->setOpenKey($data['access_token']);
            
            $ret = true;
        } else {
            $ret = false;
        }
        
        return $ret;
    }
    
    /***************************************************static function***********************************************/
    public static function makeMsdkRequest($host, $uri, $params, $cookie = array(), $method = 'post', $protocol = 'http', $logger = null, $open_id = null )
    {
        $url = "$protocol://$host$uri";

        $B = microtime(true);

        $response = \SnsNetwork::makeRequest($url, $params, $cookie, $method, $protocol, $logger, $open_id);

        $E = microtime(true);
        $X = $E - $B;
        if ($logger != null and $X > 0.3 ){
            $logger->debug("makeRequest delay call: {$X}");
        }
        
        return self::extractMsdkResponse($response,$logger);
    }
    
    public static function extractMsdkResponse($response,$logger = null)
    {
        $ret = array();
        if(isset($response['result']) && $response['result'] == 1) {
            $dec = json_decode($response['msg'], true);
            $ret = array('ret' => Application::CX_CODE_SUCCESS, 'msg' => 'success', 'data' => $dec);
        } else {
            $ret = array('ret' => Application::CX_CODE_FAILED, 'msg' => 'HTTP Response error!', 'data' => $response);
        }
    
        return $ret;
    }
    
    public static function formatResponse($code, $msg = null, $data = null, $toJson = false)
    {
        if (is_array($code) && isset($code['ret']) && isset($code['msg']) && isset($code['data'])) {
            $response = $code;
        } else {
            $response = array(
                'ret'       => $code,
                'msg'       => $msg,
                'data'      => $data,
            );
        }
    
        return $toJson ? json_encode($response) : $response;
    }
    
    public static function makeURLParamsString($params)
    {
        $ret = '';
        if (count($params) > 0) {
            $str = '?';
            foreach ($params as $key => $val) {
                $str .= "{$key}={$val}&";
            }
            $ret = substr($str, 0, strlen($str) - 1);
        }
        
        return $ret;
    }
    
    public static function sendGMCmd($data, $host, $port, $toJson = true)
    {
        $gm = new \ServerApi();
        $sdata = $toJson ? json_encode($data) : $data;
        $result = $gm->sendCommonCmd($host, $port, $sdata, \ServerApi::YUN_CHANGE_TO_GOLD);
        
        return $result;
    }
    
    public static function sendGMCmd1($data, $host, $port, $toJson = true)
    {
    	$gm = new \ServerApi();
    	$sdata = $toJson ? json_encode($data) : $data;
    	$result = $gm->sendCommonCmd($host, $port, $sdata, \ServerApi::PT_GET_QQ_POWER);
    
    	return $result;
    }
}
