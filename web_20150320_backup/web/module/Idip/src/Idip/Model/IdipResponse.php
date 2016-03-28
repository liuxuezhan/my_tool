<?php
namespace Idip\Model;

class IdipResponse extends IdipData
{
    
    const NUMBERS_PER_PAGE      = 100;

    public function __construct($data = array())
    {
        $default_response = array(
                        'head'  => array(
                            'PacketLen'     => null,
                            'Seqid'         => null,
                            'ServiceName'   => null,
                            'SendTime'      => strftime('%Y%m%d'),
                            'Version'       => null,
                            'Authenticate'  => null,
                            'Result'        => 0,
                            'RetErrMsg'     => 'success',
                        ),
                        'body'  => array(),
                    );
        $response = array_replace_recursive($default_response, $data);
        $this->head = $response['head'];
        $this->body = $response['body'];
    }
    
    public function setHead($key, $val = NULL)
    {
        if (is_array($key) && empty($val)) {
            $this->head = array_replace_recursive($this->head, $key);
        } elseif (is_string($key)) {
            $this->head[$key] = $val;
        }
    }
    
    public function setBody($key, $val = NULL)
    {
        if (is_array($key) && empty($val)) {
            $this->body = array_replace_recursive($this->body, $key);
        } elseif (is_string($key)) {
            $this->body[$key] = $val;
        }
    }
    
    public function generateResponse($json_encode = true)
    {
        $data = array(
            'head'      => $this->head,
            'body'      => $this->body,
        );
        
        return $json_encode ? json_encode($data, version_compare(PHP_VERSION, '5.4.0') >= 0 && getenv('APPLICATION_ENV') == 'development' ? JSON_UNESCAPED_UNICODE : null) : $data;
    }
}