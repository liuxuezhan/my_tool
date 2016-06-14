<?php
namespace Gateway\Model;

use Zend\InputFilter\InputFilter;
use Zend\InputFilter\InputFilterAwareInterface;
use Zend\InputFilter\InputFilterInterface;

class Server implements InputFilterAwareInterface
{
    const STATUS_CLOSED     = 0;
    const STATUS_OPEN       = 1;
    const STATUS_MERGED     = 2;
    const STATUS_MIGRATED   = 3;
    
    public static $status_list = array(
        self::STATUS_CLOSED     => 'closed',
        self::STATUS_OPEN       => 'open',
        self::STATUS_MERGED     => 'merged',
        self::STATUS_MIGRATED   => 'migrated',
    );
    
    public $id;
    public $area_id;
    public $plat_id;
    public $partition;
    public $name;
    public $ip;
    public $port;
    public $db_host;
    public $db_port;
    public $db_name;
    public $db_user;
    public $db_pass;
    public $open_time;
    public $status;
    public $ref_id;
    public $updated_at;
    
    protected $inputFilter;
    
    public function exchangeArray($data = array())
    {
        $this->id                 = (!empty($data['id'])) ? $data['id'] : null;
        $this->area_id            = (!empty($data['area_id'])) ? $data['area_id'] : null;
        $this->plat_id            = (isset($data['plat_id'])) ? $data['plat_id'] : null;
        $this->partition          = (!empty($data['partition'])) ? $data['partition'] : null;
        $this->name               = (isset($data['name'])) ? $data['name'] : null;
        $this->ip                 = (isset($data['ip'])) ? $data['ip'] : null;
        $this->port               = (isset($data['port'])) ? $data['port'] : null;
        $this->db_host            = (isset($data['db_host'])) ? $data['db_host'] : null;
        $this->db_port            = (isset($data['db_port'])) ? $data['db_port'] : 3306;
        $this->db_name            = (isset($data['db_name'])) ? $data['db_name'] : null;
        $this->db_user            = (isset($data['db_user'])) ? $data['db_user'] : null;
        $this->db_pass            = (isset($data['db_pass'])) ? $data['db_pass'] : null;
        $this->open_time          = (isset($data['open_time'])) ? $data['open_time'] : null;
        $this->status             = (isset($data['status'])) ? $data['status'] : self::STATUS_CLOSED;
        $this->ref_id             = (isset($data['ref_id'])) ? $data['ref_id'] : null;
        $this->updated_at         = strftime('%Y-%m-%d %H:%M:%S');
    }
    
    public function getArrayCopy()
    {
        return get_object_vars($this);
    }
    
    public function setInputFilter(InputFilterInterface $inputFilter)
    {
        throw new \Exception('Not nused');
    }
    
    public function getInputFilter()
    {
        if (!$this->inputFilter) {
            $inputFilter = new InputFilter();
            
            $inputFilter->add(array(
                'name'          => 'id',
                'required'      => true,
                'filters'       => array(
                    array('name'    => 'Int'),
                ),
            ));
            
            $inputFilter->add(array(
                'name'          => 'area_id',
                'required'      => true,
                'filters'       => array(
                    array('name'    => 'Int'),
                ),
            ));
            
            $inputFilter->add(array(
                'name'          => 'plat_id',
                'required'      => true,
                'filters'       => array(
                    array('name'    => 'Int'),
                ),
            ));
            
            $inputFilter->add(array(
                'name'          => 'partition',
                'required'      => true,
                'filters'       => array(
                    array('name'    => 'Int'),
                ),
            ));
            
            $inputFilter->add(array(
                'name'          => 'name',
                'required'      => true,
                'filters'       => array(
                    array('name'    => 'StripTags'),
                    array('name'    => 'StringTrim'),
                ),
                'validators'    => array(
                    array(
                        'name'      => 'StringLength',
                        'options'   => array(
                            'encoding'      => 'UTF-8',
                            'min'           => 1,
                            'max'           => 100,
                        ),
                    ),
                ),
            ));
            
            $inputFilter->add(array(
                'name'          => 'ip',
                'required'      => true,
                'filters'       => array(
                    array('name'    => 'StripTags'),
                    array('name'    => 'StringTrim'),
                ),
                'validators'    => array(
                    array(
                        'name'      => 'Ip',
                        'options'   => array(
                            'allowipv6'     => false,
                        ),
                    ),
                ),
            ));
            
            $inputFilter->add(array(
                'name'          => 'port',
                'required'      => true,
                'filters'       => array(
                    array('name'    => 'Int'),
                ),
            ));
            
            $inputFilter->add(array(
                'name'          => 'db_host',
                'required'      => true,
                'filters'       => array(
                    array('name'    => 'StripTags'),
                    array('name'    => 'StringTrim'),
                ),
                'validators'    => array(
                    array(
                        'name'      => 'StringLength',
                        'options'   => array(
                            'encoding'      => 'UTF-8',
                            'min'           => 1,
                            'max'           => 50,
                        ),
                    ),
                ),
            ));

            $inputFilter->add(array(
                'name'          => 'db_name',
                'required'      => true,
                'filters'       => array(
                    array('name'    => 'StripTags'),
                    array('name'    => 'StringTrim'),
                ),
                'validators'    => array(
                    array(
                        'name'      => 'StringLength',
                        'options'   => array(
                            'encoding'      => 'UTF-8',
                            'min'           => 1,
                            'max'           => 20,
                        ),
                    ),
                ),
            ));

            $inputFilter->add(array(
                'name'          => 'db_user',
                'required'      => true,
                'filters'       => array(
                    array('name'    => 'StripTags'),
                    array('name'    => 'StringTrim'),
                ),
                'validators'    => array(
                    array(
                        'name'      => 'StringLength',
                        'options'   => array(
                            'encoding'      => 'UTF-8',
                            'min'           => 1,
                            'max'           => 20,
                        ),
                    ),
                ),
            ));

            $inputFilter->add(array(
                'name'          => 'db_pass',
                'required'      => true,
                'filters'       => array(),
                'validators'    => array(
                    array(
                        'name'      => 'StringLength',
                        'options'   => array(
                            'encoding'      => 'UTF-8',
                            'min'           => 1,
                            'max'           => 20,
                        ),
                    ),
                ),
            ));
            
            $this->inputFilter = $inputFilter;
        }
        
        return $this->inputFilter;
    }
}