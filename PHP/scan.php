<?

	set_time_limit(0);
	ini_set('memory_limit','1024M');


	define('WORKDIR',		'C:\\RECEITA_FILES\\');
	define('DB_HOST',		'localhost');
	define('DB_USER',		'root');
	define('DB_PASS',		'as65d1f89uio231gfsd@');
	define('DB_PORT',		'6306');
	define('DB_NAME',		'receita');
	
	include('class/db.class.php');
	$db = db::getInstance();
	$dirs = scandir(WORKDIR);
	foreach ($dirs as $file) {
		if (($file == '.') || ($file == '..')) continue;
		$file_handle = fopen(WORKDIR.$file, 'rb');
		$lines = 0;
		while (!feof($file_handle)) {
			$lines += substr_count(fread($file_handle, 8192), "\n");
		}
		fclose($file_handle);
		$file_handle = fopen(WORKDIR.$file, "r");
		$line=0;
		while (!feof($file_handle)) {
		   $line++;
		   $txt = fgets($file_handle);
		   if (substr($txt,1-1,1)=='1') {
			   $params = array(
				'CNPJ'			=> trim(substr($txt,4-1,14)),
				'RAZAOSOCIAL'	=> trim(substr($txt,19-1,150)), 
				'NOMEFANTASIA'	=> trim(substr($txt,169-1,55)),
				'CNAE'			=> trim(substr($txt,376-1,7)),				
				'TELEFONE1'		=> trim(substr($txt,739-1,12)),
				'TELEFONE2'		=> trim(substr($txt,751-1,12)),
				'EMAIL'			=> trim(substr($txt,775-1,115)),
			   );
			   $sql = 'REPLACE 
							INTO 
								empresas 
							SET 
								CNPJ=:CNPJ,
								RAZAOSOCIAL=:RAZAOSOCIAL,
								NOMEFANTASIA=:NOMEFANTASIA,
								CNAE=:CNAE,
								TELEFONE1=:TELEFONE1,
								TELEFONE2=:TELEFONE2,
								EMAIL=:EMAIL
				';
		   }
		   if (substr($txt,1-1,1)=='6') {
			   $params = array(
				'CNPJ'			=> trim(substr($txt,4-1,14)),
				'CNAE'			=> trim(substr($txt,18-1,7)),				
			   );
			   $sql = 'UPDATE 
								empresas 
							SET 
								CNAE=CONCAT(CNAE,",",:CNAE)
							WHERE
								CNPJ=:CNPJ
						LIMIT
							1
				';
		   }
		   if (isset($params) && isset($sql)) { 
			   if (($params['CNAE']=='6321500') || ($params['CNAE']=='5223100') || ($params['CNAE']=='4520000')) {
				   $db->execSQL($sql,$params);
				   echo "{$params['CNAE']} SETTING TO {$params['CNPJ']}\n";
			   }
			   else {
				   $perc=round($line/($lines/100));
				   echo "SKIPPING {$params['CNPJ']} ({$perc}%)\n";
				   continue;
			   }			   
		   }
		}
		fclose($file_handle);
	}

	
?>