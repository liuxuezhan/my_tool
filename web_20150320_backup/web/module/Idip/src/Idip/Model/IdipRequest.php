<?php
namespace Idip\Model;

class IdipRequest extends IdipData
{
    
    public function __construct($data, $json_encode = false)
    {
        if ($json_encode) {
            $data = json_decode($data, true);
        }
        $this->makeHeadBody($data);
    }
    
    public function validate()
    {
        return true;
    }
}