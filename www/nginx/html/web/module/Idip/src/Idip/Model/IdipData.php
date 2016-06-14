<?php
namespace Idip\Model;

class IdipData
{
    public $head           = array();
    public $body           = array();
    
    public function makeHeadBody(array $data)
    {
        if (!isset($data['head'])) {
            throw new \Exception("Cannot find head in data");
        }
        if (!isset($data['body'])) {
            throw new \Exception("Cannot find body in data");
        }
        $this->head = $data['head'];
        $this->body = $data['body'];
        
        //!!! *fixed: empty array for lua
        if(array_key_exists('AllMailItemList', $this -> body)){
        	if(empty($this -> body['AllMailItemList'])){
        		$this -> body['AllMailItemList'] = new \stdClass();
	        	$this -> body['AllMailItemList_count'] = 0;
        	}
        }
        
    }
    
    public function getHead($key = NULL)
    {
        if (empty($key)) {
            return $this->head;
        }
        if (!array_key_exists($key, $this->head)) {
            throw new \Exception("Cannot find head with key {$key}");
        }
        return $this->head[$key];
    }
    
    public function getBody($key = NULL)
    {
        if (empty($key)) {
            return $this->body;
        }
        if (!array_key_exists($key, $this->body)) {
            throw new \Exception("Cannot find body with key {$key}");
        }
        return $this->body[$key];
    }
    
    public function getContent()
    {
    	return array(
    			'head' => $this -> head,
    			'body' => $this -> body
    	);
    }
    
    public function existHead($key)
    {
        return isset($this->head[$key]) ? true : false;
    }
    
    public function existBody($key)
    {
        return isset($this->body[$key]) ? true : false;
    }
}