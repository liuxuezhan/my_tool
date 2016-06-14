<?php
define('APP_ROOT', dirname(__FILE__) . DIRECTORY_SEPARATOR . '..' . DIRECTORY_SEPARATOR);
define('VENDOR_ROOT', APP_ROOT . 'vendor' . DIRECTORY_SEPARATOR);
define('VENDOR_YX_ROOT', VENDOR_ROOT . 'yuxiang' . DIRECTORY_SEPARATOR);
define('VENDOR_TX_ROOT', VENDOR_ROOT . 'tencent' . DIRECTORY_SEPARATOR);
define('CONFIG_ROOT', APP_ROOT . 'config' . DIRECTORY_SEPARATOR);
define('CONFIG_AUTOLOAD_DIR', CONFIG_ROOT . 'autoload' . DIRECTORY_SEPARATOR);
define('IDIP_MODEL_ROOT', APP_ROOT . 'module' . DIRECTORY_SEPARATOR . 'Idip' . DIRECTORY_SEPARATOR . 'src' . DIRECTORY_SEPARATOR . 'Idip' . DIRECTORY_SEPARATOR . 'Model' . DIRECTORY_SEPARATOR);
define('LOG_ROOT', APP_ROOT . 'logs' . DIRECTORY_SEPARATOR);

require_once CONFIG_ROOT . 'application.config.php';
require_once IDIP_MODEL_ROOT . 'Idip.php';
require_once IDIP_MODEL_ROOT . 'IdipData.php';
require_once IDIP_MODEL_ROOT . 'IdipRequest.php';
require_once IDIP_MODEL_ROOT . 'IdipResponse.php';
require_once VENDOR_YX_ROOT . 'logger.php';
require_once VENDOR_YX_ROOT . 'socket_api.php';

use Idip\Model\IdipRequest;
use Idip\Model\IdipResponse;
use Idip\Model\Idip;

$logger = Logger::getInstance();

try
{
    
    //load config files
    $config = array();
    $config_dir = opendir(CONFIG_AUTOLOAD_DIR);
    while (($file = readdir($config_dir)) !== false) {
        if ($file == '.' || $file == '..') {
            continue;
        }
        $extension = substr(strrchr($file, '.'), 1);
        if ($extension != 'php') {
            continue;
        }
        $file_config = include(CONFIG_AUTOLOAD_DIR . $file);
        $config = array_merge_recursive($config, $file_config);
    }
    
    $adapters = $config['db']['adapters'];
    
    $ts1 = microtime(true);
    
    $logger->debug('sendAction start' . $ts1);
    
    $data = $_POST['data_packet'];
    $logger->debug($data);
    $data = json_decode($data, true);
    $logger->debug($data);
    $request = new IdipRequest($data);
    //$logger->debug($idip_request);
    
    $area_id    = $request->getBody('AreaId');
    $plat_id    = $request->getBody('PlatId');
    $cmd_id     = $request->getHead('Cmdid');
    
    $ts2 = microtime(true);
    $time = $ts2 - $ts1;
    
    $response = new IdipResponse();
    $response->setHead(array(
        'Seqid'         => $request->getHead('Seqid'),
        'ServiceName'   => $request->getHead('ServiceName'),
        'Version'       => $request->getHead('Version'),
        'Authenticate'  => null,
    ));
    
    if ( !$request->existBody('Partition') || $request->getBody('Partition') == 0 ) {//查询目标大区所有服
        if ($cmd_id == 0x1027) {//查询用户角色信息
            $adapter_name = "namespace_{$area_id}_{$plat_id}";
            $adapter_config = $adapters[$adapter_name];
            $adapter = new PDO($adapter_config['dsn'], $adapter_config['username'], $adapter_config['password'], $adapter_config['driver_options']);
    
            $openid = $request->getBody('OpenId');
            $page = $request->getBody('PageNo');
            $start = ($page - 1) * IdipResponse::NUMBERS_PER_PAGE;
            $offset = IdipResponse::NUMBERS_PER_PAGE;
    
            $total_cnt = 0;
            $sql = "SELECT COUNT(*) AS cnt FROM PLAYER_TBL WHERE account = '{$openid}'";
            $logger->debug("execute sql: {$sql}");
            $result = $adapter->query($sql);
            foreach ($result as $row) {
                $total_cnt = $row['cnt'];
            }
            $total_pages = ceil($total_cnt / IdipResponse::NUMBERS_PER_PAGE);
    
            $sql = "SELECT id, name, svr_name FROM PLAYER_TBL WHERE account='{$openid}' LIMIT {$start}, {$offset}";
            $logger->info("execute sql: $sql");
            $result = $adapter->query($sql);
            $adapter = null;
    
            $res = array();
            foreach ($result as $row) {
                $res[] = array(
                    'RoleId'        => $row['id'],
                    'RoleName'      => urlencode($row['name']),
                    'Partition'     => (int) $row['svr_name'],
                    'TotalPageNo'   => $total_pages,
                );
            }
            $logger->debug($res);
    
            $response->setHead('Cmdid', 0x1028);
            $response->setBody(array(
                'RoleList_count'  => count($res),
                'RoleList'        => $res,
            ));
        } else {
            $response->setHead(array(
                'Cmdid'         => $cmd_id + 1,
                'Result'        => -101,
                'RetErrMsg'     => "CmdId({$cmd_id}) cannot be supported on multiple partitions"
            ));
            $response->setBody(array(
                'Result'        => -101,
                'RetMsg'        => "CmdId({$cmd_id}) cannot be supported on multiple partitions"
            ));
        }
    } else {//查询指定服
        $partition  = $request->getBody('Partition');
    
        //根据area_id/plat_id/partition查找数据库连接
        $adapter_name = "gateway";
        $adapter = new PDO($adapters[$adapter_name]['dsn'], $adapters[$adapter_name]['username'], $adapters[$adapter_name]['password'], $adapters[$adapter_name]['driver_options']);
    
        $sql = "SELECT ip, port, db_host, db_port, db_name, db_user, db_pass, status FROM servers WHERE area_id = {$area_id} AND plat_id = {$plat_id} AND partition = {$partition}";
        $logger->info("execute sql: $sql");
        $result = $adapter->query($sql);
        $logger->debug('find db info on gateway');
        $logger->debug(print_r($result, true));
        $adapter = null;
        
        if (empty($result)) {
            $response->setHead(array(
                'Result'        => -102,
                'RetErrMsg'     => "Cannot find this area_id/plat_id/partition on the gateway",
            ));
            $response->setBody(array(
                'Result'        => -102,
                'RetMsg'        => "Cannot find this area_id/plat_id/partition on the gateway",
            ));
        } elseif (count($result) > 1) {
            $response->setHead(array(
                'Result'        => -103,
                'RetErrMsg'     => "Multiple servers are found with this area_id/plat_id/partition on the gateway",
            ));
            $response->setBody(array(
                'Result'        => -103,
                'RetMsg'        => "Multiple servers are found with this area_id/plat_id/partition on the gateway",
            ));
        } else {
            $gs_config = array();
            foreach ($result as $row) {
                $gs_config['status'] = $row['status'];
                $gs_config['host'] = $row['db_host'];
                $gs_config['port'] = $row['db_port'];
                $gs_config['name'] = $row['db_name'];
                $gs_config['user'] = $row['db_user'];
                $gs_config['pass'] = $row['db_pass'];
    
                $gs_config['gs_ip'] = $row['ip'];
                $gs_config['gs_port'] = $row['port'];
            }
    
            if (!isset($gs_config['status'])) {
                $response->setHead(array(
                    'Result'        => -102,
                    'RetErrMsg'     => "Cannot find this area_id/plat_id/partition on the gateway",
                ));
                $response->setBody(array(
                    'Result'        => -102,
                    'RetMsg'        => "Cannot find this area_id/plat_id/partition on the gateway",
                ));
            } elseif ($gs_config['status'] != Idip::STATUS_OPEN) {
                $status_txt = Idip::$status_list[$gs_config['status']];
                $response->setHead(array(
                    'Result'        => -104,
                    'RetErrMsg'     => "This server has been {$status_txt}",
                ));
                $response->setBody(array(
                    'Result'        => -104,
                    'RetMsg'        => "This server has been {$status_txt}",
                ));
            } else {
                if ($cmd_id == 0x1029) {//查询用户基本 信息
                    $driver = array(
                        'driver'        => 'Pdo',
                        'dsn'           => "mysql:dbname={$gs_config['name']};host={$gs_config['host']};port={$gs_config['port']};charset=utf8",
                        'driver_options'=> array(
                            \PDO::MYSQL_ATTR_INIT_COMMAND => 'SET NAMES \'UTF8\''
                        ),
                        'username'      => $gs_config['user'],
                        'password'      => $gs_config['pass'],
                    );
                    $adapter = new PDO($driver['dsn'], $driver['username'], $driver['password'], $driver['driver_options']);
                    $openid = $request->getBody('OpenId');
                    $sql = "
                    SELECT
                    last_logout_ip,
                    online_time,
                    name,
                    account,
                    gold,
                    silver,
                    wood,
                    score,
                    soul,
                    power,
                    merit,
                    guild_name,
                    vip,
                    level,
                    online_time
                    FROM PLAYER_TBL
                    WHERE account='{$openid}'";
                    $logger->info("execute sql: $sql");
                    $result = $adapter->query($sql);
    
                    $res = array();
                    foreach ($result as $row) {
                        $res['Ip']              = $row['last_logout_ip'];
                        $res['OnlineTime']      = $row['online_time'];
                        $res['AvgOnlineTime']   = null;//TODO
                        $res['RoleName']        = urlencode($row['name']);
                        $res['Level']           = $row['level'];
                        $res['Diamond']         = $row['gold'];
                        $res['Money']           = $row['silver'];
                        $res['Stone']           = $row['wood'];
                        $res['Reputation']      = $row['score'];
                        $res['Soul']            = $row['soul'];
                        $res['Achieve']         = $row['merit'];
                        $res['ArmyName']        = urlencode($row['guild_name']);
                        $res['Vip']             = $row['vip'];
                        $res['Physical']        = $row['power'];
                    }
                    $logger->debug($res);
    
                        $response->setHead('Cmdid', 0x102a);
                    if (empty($res)) {
                        $response->setHead(array(
                            'Result'        => 1,
                        'RetErrMsg'     => "Cannot find this OpenID exists any partitions on this platform"
                        ));
                    }
                    $response->setBody($res);
                } else {//Send GM to GS
                    $logger->debug("Connect to server {$gs_config['gs_ip']}:{$gs_config['gs_port']}");
                    $gm = new ServerApi($logger);
                    $ret = $gm->sendIdipCmd($gs_config['gs_ip'], $gs_config['gs_port'], $data);
                    $logger->debug($ret);
    
                    $response->makeHeadBody($ret);
                }
            }
        }
    
    }
    
    $ts3 = microtime(true);
    $ret = $response->generateResponse();
    $logger->debug($ret);
    $logger->info('-------------------------------------------');
    
    echo $ret;
    $time = $ts3 - $ts2;
    $total = $ts3 - $ts1;
    
    $logger->debug("sendAction return: {$ts3}, total time {$total}");


}
catch (Exception $e){
    $logger->debug($e.msg);
}
