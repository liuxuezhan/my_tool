<?php
require('Application.php');
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
	        'appid'         => QQ_APPID,
	        'openid'        => $this->openid,
	        'timestamp'     => $ts,
	        'sig'           => self::makeTxSignature(QQ_APPKEY, $ts),
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
        $result = md5($openid . $ts . self::CX_CERTIFY_KEY);
        return $result;
    }
}