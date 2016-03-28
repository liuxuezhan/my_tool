<?php
namespace Idip\Model;

class Idip
{
    //The following status is copied from gateway, Please keep it the same as gateway!!!
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
}