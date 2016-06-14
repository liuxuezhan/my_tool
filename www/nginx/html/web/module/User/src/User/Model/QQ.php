<?php
namespace User\Model;

class QQ extends User
{
    private $_pf;
    
    private $signString;
    
    public function __construct($appid, $appkey)
    {
    	$this -> _pf = parent::ePlatform_QQ;
    	$this -> signString = parent::CX_SIG_RELATION_KEY;
        $this->setAppId($appid);
        $this->setAppKey($appkey);
        $this->setPlatform(parent::ePlatform_QQ);
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
        $config     = $this->getServiceLocator()->get('config');
        
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
        $logger     = $this->getServiceLocator()->get('Zend\Log');
        $config     = $this->getServiceLocator()->get('config');
        
        $host       = $config['msdk']['host'];
        $url_path   = '/relation/qqprofile';
        
        $url_params = $this->generateMsdkUrlParamString();
        $uri = $url_path . $url_params;
        $logger->debug($uri);
        
        $params = array(
            'appid'         => $this->appid,
            'openid'        => $this->openid,
            'accessToken'   => $this->openkey,
        );
        
        $response = $this->makeMsdkRequest($host, $uri, json_encode($params), array(), 'post', 'http',$logger, $this->appid);
        $logger->debug($response);
        
        return $response;
    }
    
    public function getFriends($data)
    {
        $logger     = $this->getServiceLocator()->get('Zend\Log');
        $config     = $this->getServiceLocator()->get('config');
    
        $host       = $config['msdk']['host'];
        $url_path   = '/relation/qqfriends_detail';
        $flag       = 1;//1 or 2
        
        $url_params = $this->generateMsdkUrlParamString();
        $uri = $url_path . $url_params;
        $logger->debug($uri);
    
        $params = array(
            'appid'         => $this->appid,
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
        
        $host       = $config['msdk']['host'];
        $url_path   = '/auth/guest_check_token';
        $ts         = time();
        $encode     = 1;
        
        $logger->debug($this->appkey);
        $url_params = self::makeURLParamsString(array(
            'timestamp'     => $ts,
            'appid'         => $this->appid,
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
    
    public static function makeCxSignature1($params, $logger = NULL)
    {
    	$str = join('', $params);
    	if (!empty($logger))
    		$logger->debug($str);
    	$md5_str = md5($str);
    	if (!empty($logger))
    		$logger->debug($md5_str);
    	return $md5_str;
    }
    /*****************************************************static function*****************************************************/

}