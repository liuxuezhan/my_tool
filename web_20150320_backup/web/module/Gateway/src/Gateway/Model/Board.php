<?php
namespace Gateway\Model;

use Application\Model\Application;

class Board extends Application
{
    public $open_id;
    public $platform;
    public $scorewar_data;
    public $rankwar_data;
    public $stage_data;
    public $elite_stage_data;
    public $max_gs;
    public $update_time;
    
    public function exchangeArray($data = array())
    {
        $this->open_id            = (!empty($data['open_id'])) ? $data['open_id'] : null;
        $this->platform           = (!empty($data['platform'])) ? $data['platform'] : null;
        $this->scorewar_data      = (isset($data['scorewar_data'])) ? $data['scorewar_data'] : null;
        $this->rankwar_data       = (isset($data['rankwar_data'])) ? $data['rankwar_data'] : null;
        $this->stage_data         = (isset($data['stage_data'])) ? $data['stage_data'] : null;
        $this->elite_stage_data   = (isset($data['elite_stage_data'])) ? $data['elite_stage_data'] : null;
        $this->max_gs             = (isset($data['max_gs'])) ? $data['max_gs'] : null;
        $this->update_time        = time();
    }
    
    /*****************************************************static function*****************************************************/
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