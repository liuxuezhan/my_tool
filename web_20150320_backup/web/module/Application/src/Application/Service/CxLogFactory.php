<?php

namespace Application\Service;

use Zend\ServiceManager\FactoryInterface;
use Zend\ServiceManager\ServiceLocatorInterface;

class CxLogFactory implements FactoryInterface
{

	public function createService(ServiceLocatorInterface $serviceLocator)
	{
		$log = new \Zend\Log\Logger();
		if (!is_dir(dirname(LOG_FILENAME))) {
			@mkdir(dirname(LOG_FILENAME), 0775);
		}
		if (!is_writable(LOG_FILENAME)) {
			die('Log file "' . realpath(LOG_FILENAME) . '" is not writable.');
		}
		if (!file_exists(LOG_FILENAME)) { // if exist dir, try to create it.
			file_put_contents(LOG_FILENAME, "--log start--\n");
		}
		$writer = new \Zend\Log\Writer\Stream(LOG_FILENAME);
		$log -> addWriter($writer);
		return $log;
	}
}