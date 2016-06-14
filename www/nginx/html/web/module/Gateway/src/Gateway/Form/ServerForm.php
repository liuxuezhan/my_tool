<?php
namespace Gateway\Form;

use Zend\Form\Form;

class ServerForm extends Form
{
    public function __construct($name = null, $options = array())
    {
        parent::__construct('server', $options);
        
        $this->add(array(
            'name'      => 'id',
            'type'      => 'Hidden',
        ));
        
        $this->add(array(
            'name'      => 'area_id',
            'type'      => 'Select',
            'options'   => array(
                'label'     => 'Area ID',
            ),
        ));
        
        $this->add(array(
            'name'      => 'plat_id',
            'type'      => 'Select',
            'options'   => array(
                'label'     => 'Platform',
            ),
        ));
        
        $this->add(array(
            'name'      => 'partition',
            'type'      => 'Text',
            'options'   => array(
                'label'     => 'Partition',
            ),
        ));
        
        $this->add(array(
            'name'      => 'name',
            'type'      => 'Text',
            'options'   => array(
                'label'     => 'Name',
            ),
        ));
        
        $this->add(array(
            'name'      => 'ip',
            'type'      => 'Text',
            'options'   => array(
                'label'     => 'IP',
            ),
        ));
        
        $this->add(array(
            'name'      => 'port',
            'type'      => 'Text',
            'options'   => array(
                'label'     => 'Port',
            ),
        ));
        
        $this->add(array(
            'name'      => 'db_host',
            'type'      => 'Text',
            'options'   => array(
                'label'     => 'DB Host',
            ),
        ));
        
        $this->add(array(
            'name'      => 'db_port',
            'type'      => 'Text',
            'options'   => array(
                'label'     => 'DB port',
            ),
            'attributes'    => array(
                'value'         => '3306',
            ),
        ));
        
        $this->add(array(
            'name'      => 'db_name',
            'type'      => 'Text',
            'options'   => array(
                'label'     => 'DB Name',
            ),
        ));
        
        $this->add(array(
            'name'      => 'db_user',
            'type'      => 'Text',
            'options'   => array(
                'label'     => 'DB Username',
            ),
        ));
        
        $this->add(array(
            'name'      => 'db_pass',
            'type'      => 'Text',
            'options'   => array(
                'label'     => 'DB Password',
            ),
        ));
        
        $this->add(array(
            'name'      => 'open_time',
            'type'      => 'Hidden',
        ));
        
        $this->add(array(
            'name'      => 'status',
            'type'      => 'Hidden',
        ));
        
        $this->add(array(
            'name'      => 'ref_id',
            'type'      => 'Hidden',
        ));
        
        $this->add(array(
            'name'      => 'submit',
            'type'      => 'Submit',
            'attributes'    => array(
                'value'         => 'Add',
                'id'            => 'btnSubmit',
            ),
        ));
        
        $this->add(array(
            'name'      => 'back',
            'type'      => 'Button',
            'attributes'    => array(
                'value'         => 'Back',
                'id'            => 'btnBack',
            ),
        ));

    }
    
}