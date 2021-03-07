require 'aws-sdk'
require 'rack'
require 'rack/request'

class HomeController < ApplicationController
    def index
      if @resposta_get != nil
        redirect_to "/"
      end
    end

    def ativar

      arquivo = params[:arquivo]

      s3 = Aws::S3::Resource.new(
        region: 'us-west-2',
        access_key_id: ENV['AWS_ACCESS_KEY_ID'],
        secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
      )

      obj = s3.bucket('extrair').object(arquivo.original_filename)
      obj.upload_file(arquivo.tempfile)

      client = Aws::Textract::Client.new({ #Faz uma conexão com a aws usando o Textract. Obs: só esta funcionando a região aplicada.
        region: 'us-west-2',
        access_key_id: ENV['AWS_ACCESS_KEY_ID'], #pedir a kei e criar variavel de ambiente
        secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'] #pedir o acesso e criar variavel de ambiente
      })
    
      resposta = client.start_document_analysis({ #inicia uma detecção assincrona e retorna um objeto job_id
          document_location: { # required
            s3_object: {
              bucket: "extrair", #nome do bucket que será lido
              name: arquivo.original_filename, #nome do arquivo que será lido
            }
          },
          feature_types: ["TABLES"] #o tipo do arquivo que será extraido no caso de pdf 'TABLES'
      })
      
      begin
        @resposta_get = client.get_document_analysis({ #analisa o job_id e retorna os dados
          job_id: resposta[:job_id] # required
        })
      end while(@resposta_get[:job_status] == "IN_PROGRESS") #Fica lendo os dados até ele retorna que terminou

      render :index
    end

end
