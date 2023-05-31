const AWS = require('aws-sdk');
const Tesseract = require('tesseract.js');

// Configuração das credenciais da AWS
AWS.config.update({ region: 'us-east-1' });

// Configuração do cliente da AWS Rekognition
const rekognition = new AWS.Rekognition();

// Configuração do cliente da AWS Textract
const textract = new AWS.Textract();

// Função para processar a imagem usando o OCR
async function processImage(imagePath) {
  try {
    // Utiliza o AWS Rekognition para detectar e extrair o código de barras da imagem
    const barcodeData = await rekognition.detectBarcodes({
      Image: {
        S3Object: {
          Bucket: 'my-bucket',
          Name: imagePath,
        },
      },
    }).promise();

    // Extrai o valor do código de barras
    const barcodeValue = barcodeData.Barcodes[0].BarcodeValue;

    // Utiliza o AWS Textract para extrair o texto do restante da imagem
    const textData = await textract.startDocumentTextDetection({
      DocumentLocation: {
        S3Object: {
          Bucket: 'my-bucket',
          Name: imagePath,
        },
      },
    }).promise();

    // Aguarda a conclusão do processo de extração de texto
    const jobStatus = await waitForTextractJobCompletion(textData.JobId);

    // Obtém o resultado do texto extraído
    const extractedText = await textract.getDocumentTextDetection({
      JobId: textData.JobId,
    }).promise();

    // Extrai as informações relevantes do texto extraído, com base no código de barras, por exemplo

    // Retorna os resultados
    return {
      barcode: barcodeValue,
      extractedText: extractedText,
    };
  } catch (error) {
    console.error('Erro ao processar a imagem:', error);
    throw error;
  }
}

// Função auxiliar para aguardar a conclusão do processo de extração de texto do Textract
async function waitForTextractJobCompletion(jobId) {
  try {
    const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
    let status = '';

    while (status !== 'SUCCEEDED') {
      const response = await textract.getDocumentTextDetection({
        JobId: jobId,
      }).promise();

      status = response.JobStatus;
      if (status === 'FAILED') {
        throw new Error('O processo de extração de texto do Textract falhou.');
      }

      await delay(5000); // Aguarda 5 segundos antes de verificar novamente o status
    }

    return status;
  } catch (error) {
    console.error('Erro ao aguardar a conclusão do processo de extração de texto do Textract:', error);
    throw error;
  }
}

// Exemplo de uso da função processImage
const imagePath = 'example.jpg'; // Caminho da imagem no S3
processImage(imagePath)
  .then((result) => {
    console.log('Resultado:', result);
  })
  .catch((error) => {
    console.error('Erro ao processar a imagem:', error);
  });
