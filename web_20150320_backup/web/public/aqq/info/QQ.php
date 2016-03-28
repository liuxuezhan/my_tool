<?php
require('User.php');
class QQ extends User
{
	const CX_CODE_SUCCESS           = 1;
	const CX_CODE_FAILED            = 0;
	
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
	
    private $_pf        = QQ::ePlatform_QQ;
    
    private $signString = QQ::CX_SIG_RELATION_KEY;
    
    public function __construct($appid, $appkey)
    {
        $this->setAppId($appid);
        $this->setAppKey($appkey);
        $this->setPlatform(QQ::ePlatform_QQ);
    }
    
    public function validate($data)
    {
        //invoke parent validate method
        $ret = parent::validate($data);
        
        if ($ret) {
            if (!isset($data['open_id'])) {
                $ret = false;
                $this->validationErrors[] = 'open_id cannot be null';
            }
            if (!isset($data['access_token'])) {
                $ret = false;
                $this->validationErrors[] = 'access_token cannot be null';
            }
        }
        
        return $ret;
    }
    
    public function store($data, $is_validate = true)
    {
        $config     = require_once CONFIG_ROOT . 'application.config.php';
        
        if ($this->validate($data)) {
            $ret = parent::store($data);
            
            if ($this->platform == self::ePlatform_Weixin || $this->platform == self::ePlatform_QQ) {
                $this->setAppId($config['platform'][$this->platform]['appid']);
                $this->setAppKey($config['platform'][$this->platform]['appkey']);
            } elseif ($this->platform == self::ePlatform_Guest) {//appid/openid need to add G_ prefix when in guest mode
                $this->setAppId($config['platform'][$this->platform]['prefix'] . $config['platform'][self::ePlatform_QQ]['appid']);
                $this->setAppKey($config['platform'][self::ePlatform_QQ]['appkey']);
            } else {//QQHall,WTLogin is not supported now
                $this->validationErrors[] = 'This platform is not supported now';
                $ret = $this->validationErrors;
            }
        } else {
            $ret = $this->validationErrors;
        }
    
        return $ret;
    }
    
    public function getProfile($data)
    {
        $logger = Logger::getInstance();
//         $config     = require_once CONFIG_ROOT . 'application.config.php';
        
        $host       = AQQ_HOST;//"msdktest.qq.com";//$config['msdk']['host'];
        $url_path   = '/relation/qqprofile';
        
        $url_params = $this->generateMsdkUrlParamString();
        $uri = $url_path . $url_params;
        $logger->debug($uri);
        
        $params = array(
            'appid'         => QQ_APPID,
            'openid'        => $this->openid,
            'accessToken'   => $this->openkey,
        );
        $response = $this->makeMsdkRequest($host, $uri, json_encode($params), array(), 'post', 'http');
        $logger->debug($response);
        
        return $response;
    }
    
    public function getFriends($data)
    {
        $logger = Logger::getInstance();
        $config     = require_once CONFIG_ROOT . 'application.config.php';
    
        $host       = AQQ_HOST;//"msdktest.qq.com";//$config['msdk']['host'];
        $url_path   = '/relation/qqfriends_detail';
        $flag       = 1;//1 or 2
        
        $url_params = $this->generateMsdkUrlParamString();
        $uri = $url_path . $url_params;
        $logger->debug($uri);
    
        $params = array(
            'appid'         => QQ_APPID,
            'openid'        => $this->openid,
            'accessToken'   => $this->openkey,
            'flag'          => $flag,
        );
    
        $response = $this->makeMsdkRequest($host, $uri, json_encode($params));
        $logger->debug($response);
        
        return $response;
    }
    
    public function guestCheckToken($data)
    {
        $logger     = $this->getServiceLocator()->get('Zend\Log');
        $config     = $this->getServiceLocator()->get('config');
        
        $host       = AQQ_HOST;//"msdktest.qq.com";//$config['msdk']['host'];
        $url_path   = '/auth/guest_check_token';
        $ts         = time();
        $encode     = 1;
        
        $logger->debug($this->appkey);
        $url_params = self::makeURLParamsString(array(
            'timestamp'     => $ts,
            'appid'         => QQ_APPID,
            'sig'           => self::makeTxSignature($this->appkey, $ts),
            'openid'        => $this->openid,
            'encode'        => $encode,
        ));
        $uri = $url_path . $url_params;
        $logger->debug($uri);
        
        $params = array(
            'guestid'       => $this->openid,
            'accessToken'   => $this->openkey,
        );
        $logger->debug($params);
        
        $response = $this->makeMsdkRequest($host, $uri, json_encode($params));
        $logger->debug($response);
        
        return $response;
    }
    
    public function checkToken($openid,$time,$sign)
    {
    	
    	if(isset($openid) && isset($time) && isset($sign))
    	{
    		$signHere = md5($openid.$time.$this->signString);
    		//echo "<br/>本地签名：".$signHere."<br/>";
    		//echo "客户端上传签名：".$sign."<br/>";
    		$signHere = strtoupper($signHere);
    		if($signHere == $sign)
    		{
    			return true;
    		}
    	}
    	return false;
    }
    /*****************************************************static function*****************************************************/

}