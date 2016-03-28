<?php
namespace User\Model;

use Application\Model\Application;

class User extends Application
{
	public $openid;
	public $platform;
	public $scorewar_data;
	public $rankwar_data;
	public $update_time;
	
	public function exchangeArray($data = array())
	{
	    $this->openid            = (!empty($data['open_id'])) ? $data['open_id'] : null;
	    $this->platform           = (!empty($data['platform'])) ? $data['platform'] : null;
	    $this->scorewar_data      = (isset($data['scorewar_data'])) ? $data['scorewar_data'] : 0;
	    $this->rankwar_data       = (isset($data['rankwar_data'])) ? $data['rankwar_data'] : 0;
	    $this->update_time        = time();
	}
	
	protected function generateMsdkUrlParamString($ts = NULL, $encode = 1)
	{
	    if (empty($ts)) {
	        $ts = time();
	    }
	    
	    $url_params = array(
	        'appid'         => $this->appid,
	        'openid'        => $this->openid,
	        'timestamp'     => $ts,
	        'sig'           => self::makeTxSignature($this->appkey, $ts),
	        'encode'        => $encode,
	    );
	    
	    return self::makeURLParamsString($url_params);
	}
	
	public function signCxResponse($data)
	{
	    if (empty($data)) {
	        throw new \Exception('Signature field is null');
	    } else {
	        $ts =  isset($data['time']) ? $data['time'] : time();
	        $sig = self::makeCxSignature($this->openid, $ts);
	        $data['time'] = $ts;
	        $data['flag'] = $sig;
	
	        return $data;
	    }
	}
	
    /*****************************************************static function*****************************************************/
    public static function makeTxSignature($appkey, $ts)
    {
        $result = md5($appkey . $ts);
        return $result;
    }
    
    public static function makeCxSignature($openid, $ts)
    {
        $result = md5($openid . $ts . parent::CX_SIG_FRIENDS_KEY);
        return $result;
    }
}