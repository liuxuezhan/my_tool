<?php
namespace User\Model;

use Application\Model\Application;

class WX extends User
{
    public $_pf         = WX::ePlatform_Weixin;
    
    public function __construct($appid, $appkey)
    {
    	$this -> _pf = parent::ePlatform_Weixin;
        $this->setAppId($appid);
        $this->setAppKey($appkey);
        $this->setPlatform(parent::ePlatform_Weixin);
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
                $this->setAppId($config['platform'][$this->platform]['prefix'] . $config['platform'][self::ePlatform_Weixin]['appid']);
                $this->setAppKey($config['platform'][self::ePlatform_Weixin]['appkey']);
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
        $url_path   = '/relation/wxuserinfo';
    
        $url_params = $this->generateMsdkUrlParamString();
        $uri = $url_path . $url_params;
        $logger->debug($uri);
    
        $params = array(
            'appid'         => $this->appid,
            'openid'        => $this->openid,
            'accessToken'   => $this->openkey,
        );
        $logger->debug($params);
    
        $response = $this->makeMsdkRequest($host, $uri, json_encode($params));
        $logger->debug($response);
    
        return $response;
    }
    
    public function getFriendsOpenIds($data)
    {
        $logger     = $this->getServiceLocator()->get('Zend\Log');
        $config     = $this->getServiceLocator()->get('config');
        
        $host       = $config['msdk']['host'];
        $url_path   = '/relation/wxfriends';
        
        $url_params = $this->generateMsdkUrlParamString();
        $uri = $url_path . $url_params;
        $logger->debug($uri);
        
        $params = array(
            'openid'        => $this->openid,
            'accessToken'   => $this->openkey,
        );
        
        $response = $this->makeMsdkRequest($host, $uri, json_encode($params));
        $logger->debug($response);
        
        return $response;
    }
    
    public function getFriendsInfo($data)
    {
        $logger     = $this->getServiceLocator()->get('Zend\Log');
        $config     = $this->getServiceLocator()->get('config');
    
        $host       = $config['msdk']['host'];
        $url_path   = '/relation/wxprofile';
    
        $url_params = $this->generateMsdkUrlParamString();
        $uri = $url_path . $url_params;
        $logger->debug($uri);
    
        $params = array(
            'openids'       => $data['openids'],
            'accessToken'   => $this->openkey,
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
    
    /*****************************************************static function*****************************************************/
    
}