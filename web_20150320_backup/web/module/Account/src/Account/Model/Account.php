<?php
namespace Account\Model;

use Application\Model\Application;

class Account extends Application
{
	public $id;
	public $openid;
	public $refreshed_at;
	public $expired_at;
	
	public $payid;
	public $paykey;
	public $pf;
	public $pfkey;
	public $paytoken;
	
	public function __construct()
	{
	    parent::__construct();
	}
	
	public function exchangeArray($data)
	{
	    $this->id     = (!empty($data['id'])) ? $data['id'] : null;
	    $this->openid = (!empty($data['openid'])) ? $data['openid'] : null;
	    $this->refreshed_at  = (!empty($data['refreshed_at'])) ? $data['refreshed_at'] : null;
	    $this->expired_at  = (!empty($data['expired_at'])) ? $data['expired_at'] : null;
	}
	
	public function setPayId($payid)
	{
	    $this->payid = $payid;
	}
	
	public function setPayKey($paykey)
	{
	    $this->paykey = $paykey;
	}
	
	public function setPf($pf)
	{
	    $this->pf = $pf;
	}
	
	public function setPfKey($pfkey)
	{
	    $this->pfkey = $pfkey;
	}
	
	public function setPayToken($paytoken)
	{
	    $this->paytoken = $paytoken;
	}
	

	public function validate($data)
	{
	    if (
	        isset($data['open_id'])
	        && isset($data['access_token'])
	        && isset($data['os'])
	        && isset($data['platform'])
	        && isset($data['pay_token'])
	        && isset($data['pf'])
	        && isset($data['pf_key'])
	        && isset($data['zoneid'])
	    ) {
	        return true;
	    } else {
	        return false;
	    }
	}
	
	public function store($data, $is_validate = true)
	{
	    $config     = $this->getServiceLocator()->get('config');
	    
	    if ($this->validate($data)) {
	        $this->setPlatform($data['platform']);
	        $this->setOs($data['os']);
	        $this->setAppId($config['platform'][$this->platform]['appid']);
	        $this->setAppKey($config['platform'][$this->platform]['appkey']);
	        $this->setOpenId($data['open_id']);
	        $this->setOpenKey($data['access_token']);
	        $os_idx = strval($this->os);
	        $this->setPayId($config['cpay'][$os_idx]['payid']);
	        $this->setPayKey($config['cpay'][$os_idx]['paykey']);
	        $this->setPf($data['pf']);
	        $this->setPfKey($data['pf_key']);
	        $this->setZoneId($data['zoneid']);
	        $this->setPayToken($data['pay_token']);
	        
	        $ret = true;
	    } else {
	        $ret = false;
	    }
	
	    return $ret;
	}
	
	public function getBalance($data)
	{
	    $logger     = $this->getServiceLocator()->get('Zend\Log');
	    $config     = $this->getServiceLocator()->get('config');
	    
	    $host       = $config['msdk']['host'];
	    $url_path   = '/mpay/get_balance_m';
	    $ts         = time();
	    
	    $url = "http://$host$url_path";
	    $logger->info($url);
	    
	    $params = $this->signTxRequest($url_path, array(
	        'ts'       => $ts,
	    ));
	    $logger->info($params);
	    
	    $cookie = $this->getTxRequestCookie($url_path);
	    $logger->info($cookie);
	    
	    $response = self::makeMsdkRequest($host, $url_path, $params, $cookie, 'GET', 'http', $logger);
	    $logger->debug($response);
	    
	    return $response;
	}
	
	public function pay($data)
	{
	    $logger     = $this->getServiceLocator()->get('Zend\Log');
	    $config     = $this->getServiceLocator()->get('config');
	     
	    $host       = $config['msdk']['host'];
	    $url_path   = '/mpay/pay_m';
	    $ts         = time();
	     
	    $url = "http://$host$url_path";
	    $logger->info($url);
	     
	    $params = $this->signTxRequest($url_path, array(
	        'ts'       => $ts,
	        'amt'      => $data['amt'],
	        'userip'   => $_SERVER['REMOTE_ADDR'],
	        'payitem'  => $data['payitem'],
	        //'accounttype'   => 'common',//security
	        //'format'        => 'json',
	    ));
	    $logger->info($params);
	     
	    $cookie = $this->getTxRequestCookie($url_path);
	    $logger->info($cookie);
	     
	    $response = self::makeMsdkRequest($host, $url_path, $params, $cookie, 'get');
	    $logger->debug($response);
	    
	    return $response;
	}
	
	public function cancelPay($data)
	{
	    $logger     = $this->getServiceLocator()->get('Zend\Log');
	    $config     = $this->getServiceLocator()->get('config');
	    
	    $host       = $config['msdk']['host'];
	    $url_path   = '/mpay/cancel_pay_m';
	    $ts         = time();
	    
	    $url = "http://$host$url_path";
	    $logger->info($url);
	    
	    $params = $this->signTxRequest($url_path, array(
	        'ts'       => $ts,
	        'amt'      => $data['amt'],
            'billno'   => $data['billno'],
            'userip'   => $_SERVER['REMOTE_ADDR'],
	        //'format'        => 'json',
	    ));
	    $logger->info($params);
	    
	    $cookie = $this->getTxRequestCookie($url_path);
	    $logger->info($cookie);
	    
	    $response = self::makeMsdkRequest($host, $url_path, $params, $cookie, 'get');
	    $logger->debug($response);
	    
	    return $response;
	}
	
	public function getTxRequestCookie($url_path)
	{
	    $config     = $this->getServiceLocator()->get('config');
	    
	    $sessionid  = $config['platform'][$this->platform]['cpay_sessionid'];
	    $sessiontype= $config['platform'][$this->platform]['cpay_sessiontype'];
	    
	    $cookie = array(
	        'session_id'    => $sessionid,
	        'session_type'  => $sessiontype,
	        'org_loc'       => $url_path,
	        //'appip'         => $_SERVER['REMOTE_ADDR'],
	    );
	    
	    return $cookie;
	}
	
	public function signTxRequest($url_path, $params)
	{
	    $logger     = $this->getServiceLocator()->get('Zend\Log');
	    
	    $default_params = array(
	        'openid'        => $this->openid,
	        'openkey'       => $this->openkey,
	        'pay_token'     => $this->paytoken,
	        'appid'         => $this->payid,
	        'ts'            => time(),
	        'pf'            => $this->pf,
	        'pfkey'         => $this->pfkey,
	        'zoneid'        => $this->zoneid,
	        //'format'        => 'json',
	    );
	    
	    $params = array_merge($default_params, $params);
	    $logger->debug($params);
	    
	    $secret = $this->paykey . '&';
	    
	    $sig = \SnsSigCheck::makeSig('GET', $url_path, $params, $secret);
	    $params['sig'] = $sig;
	    
	    return $params;
	}
	
	public function signCxResponse($data)
	{
	    if (empty($data)) {
	        throw new \Exception('Signature field is null');
	    } else {
	        $ts =  isset($data['time']) ? $data['time'] : time();
	        $sig = isset($data['flag']) ? $data['flag'] : self::makeCxSignature(array($this->openid, $ts));
	        $data['time'] = $ts;
	        $data['flag'] = $sig;
	
	        return $data;
	    }
	}
	
	/*****************************************************static function*****************************************************/
	public static function makeTxSignature($params, $paykey, $url_path)
	{
	    $secret = $paykey . '&';
	    //调用SnsSigCheckModel::makeSig接口计算签名
	    $sig = \SnsSigCheck::makeSig('GET', $url_path, $params, $secret) ;
	    //合并签名到参数
	    return $sig;
	}
	
    public static function makeCxSignature($params, $logger = NULL)
    {
        $str = join('', $params);
        if (!empty($logger))
            $logger->debug($str);
        $md5_str = md5($str);
        if (!empty($logger))
            $logger->debug($md5_str);
        return $md5_str;
    }
}