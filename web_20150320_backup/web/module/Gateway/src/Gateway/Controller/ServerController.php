<?php
namespace Gateway\Controller;

use Zend\Mvc\Controller\AbstractActionController;
use Zend\View\Model\ViewModel;
use Gateway\Model\Server;
use Gateway\Form\ServerForm;

class ServerController extends AbstractActionController
{
    private $serverTable;
    
    private function getServerTable()
    {
        if (!$this->serverTable) {
            $this->serverTable = $this->getServiceLocator()->get('Gateway\Model\ServerTable');
        }
        return $this->serverTable;
    }
    
    public function indexAction()
    {
        $logger = $this->getServiceLocator()->get('Zend\Log');
        $config = $this->getServiceLocator()->get('config');
        
        $servers = $this->getServerTable()->fetchAll();
        
        return new ViewModel(array(
            'servers'       => $servers,
            'tx_area_list'  => $config['tx_area_list'],
            'tx_plat_list'  => $config['tx_plat_list'],
            'status_list'   => Server::$status_list,
        ));;
    }
    
    public function addAction()
    {
        $logger = $this->getServiceLocator()->get('Zend\Log');
        $config = $this->getServiceLocator()->get('config');
        
        $form = new ServerForm();
        $form->get('area_id')->setAttribute('options', $config['tx_area_list']);
        $form->get('plat_id')->setAttribute('options', $config['tx_plat_list']);
        $form->get('submit')->setValue('Add');
        
        $request = $this->getRequest();
        if ($request->isPost()) {
            $server = new Server();
            $form->setInputFilter($server->getInputFilter());
            $form->setData($request->getPost());
            
            if ($form->isValid()) {
                $server->exchangeArray($form->getData());
                $this->getServerTable()->saveServer($server);
                
                return $this->redirect()->toRoute('server');
            }
        }
        
        return array(
            'form'  => $form,
        );
    }
    
    public function editAction()
    {
        $logger = $this->getServiceLocator()->get('Zend\Log');
        $config = $this->getServiceLocator()->get('config');
        
        $id = (int) $this->params()->fromRoute('id', 0);
        if (!$id) {
            return $this->redirect()->toRoute('server', array(
                'action'    => 'index',
            ));
        }
        
        $server = $this->getServerTable()->getServer($id);
        if (empty($server)) {
            return $this->redirect()->toRoute('server', array(
                'action'    => 'index',
            ));
        }
        
        $form = new ServerForm();
        $form->bind($server);
        
        $form->get('area_id')->setAttributes(array(
            'options'       => $config['tx_area_list'],
            'value'         => $server->area_id,
        ));
        $form->get('plat_id')->setAttributes(array(
            'options'       => $config['tx_plat_list'],
            'value'         => $server->plat_id,
        ));
        $form->get('submit')->setAttribute('value', 'Edit');
        
        $request = $this->getRequest();
        if ($request->isPost()) {
            $form->setInputFilter($server->getInputFilter());
            $form->setData($request->getPost());
            if ($form->isValid()) {
                $this->getServerTable()->saveServer($server);
                
                return $this->redirect()->toRoute('server');
            }
        }
        
        return array(
            'id'    => $id,
            'form'  => $form,
        );
    }
    
    public function closeAction()
    {
        $logger = $this->getServiceLocator()->get('Zend\Log');
        $config = $this->getServiceLocator()->get('config');
        
        $id = (int) $this->params()->fromRoute('id', 0);
        if (!$id) {
            return $this->redirect()->toRoute('server', array(
                'action'    => 'index',
            ));
        }
        
        $server = $this->getServerTable()->getServer($id);
        if (empty($server)) {
            return $this->redirect()->toRoute('server', array(
                'action'    => 'index',
            ));
        }
        
        $form = new ServerForm();
        //$form->bind($server);
        
        $form->get('submit')->setAttribute('value', 'Confirm');
        
        if ($this->params()->fromPost('submit') == 'Confirm') {//Confirm to close
            if ($server->status == Server::STATUS_OPEN) {
                $server->status = Server::STATUS_CLOSED;
                
                $this->getServerTable()->saveServer($server);
            }
            return $this->redirect()->toRoute('server');
        }
        
        return array(
            'id'    => $id,
            'form'  => $form,
        );
    }
    
    public function openAction()
    {
        $logger = $this->getServiceLocator()->get('Zend\Log');
        $config = $this->getServiceLocator()->get('config');
    
        $id = (int) $this->params()->fromRoute('id', 0);
        if (!$id) {
            return $this->redirect()->toRoute('server', array(
                'action'    => 'index',
            ));
        }
    
        $server = $this->getServerTable()->getServer($id);
        if (empty($server)) {
            return $this->redirect()->toRoute('server', array(
                'action'    => 'index',
            ));
        }
    
        $form = new ServerForm();
        //$form->bind($server);
    
        $form->get('submit')->setAttribute('value', 'Confirm');
    
        if ($this->params()->fromPost('submit') == 'Confirm') {//Confirm to open
            if ($server->status == Server::STATUS_CLOSED) {
                $server->status = Server::STATUS_OPEN;
                $server->open_time = strftime('%Y-%m-%d %H:%M:%S');
                
                $this->getServerTable()->saveServer($server);
            }
            return $this->redirect()->toRoute('server');
        }
    
        return array(
            'id'    => $id,
            'form'  => $form,
        );
    }
    
    public function mergeAction()
    {
        //TODO
        $form = new ServerForm();
        
        return array(
            'form'      => $form,
        );
    }
    
    public function migrateAction()
    {
        //TODO
        $form = new ServerForm();
        
        return array(
            'form'      => $form,
        );
    }
    
}