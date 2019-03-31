#include "ACTCP_ConfIpcClient.h"
#include <boost/scoped_ptr.hpp>

ACTCP_ConfIpcClient::ACTCP_ConfIpcClient(boost::asio::io_service & io_service,
							 tcp::endpoint & ed):
m_io_service( io_service ),
m_socket( io_service ),
m_endpoint( ed )
{
}

ACTCP_ConfIpcClient::~ACTCP_ConfIpcClient(void)
{
}

void ACTCP_ConfIpcClient::Start()
{
	m_socket.async_connect(m_endpoint, boost::bind(&ACTCP_ConfIpcClient::handle_connect, this,
		boost::asio::placeholders::error));

	//boost::asio::async_connect(m_socket, m_endpoint.,
	//	boost::bind(&ACTCP_ConfIpcClient::handle_connect, this,
	//	boost::asio::placeholders::error));
}

void ACTCP_ConfIpcClient::do_close()
{
	m_socket.close();	
}

void ACTCP_ConfIpcClient::handle_write( const boost::system::error_code& error )
{
	if (!error)
	{
		boost::scoped_ptr<ACTCP_Message> message_ptr( m_write_msgs.front() );
		m_write_msgs.pop_front();

		if (!m_write_msgs.empty())
		{
			ACTCP_Message * msg_ptr = m_write_msgs.front();
			
			boost::asio::async_write(m_socket,
				boost::asio::buffer(msg_ptr->cBuffer,msg_ptr->nLen),
				boost::bind(&ACTCP_ConfIpcClient::handle_write, this,
				boost::asio::placeholders::error));
		}
	}
	else
	{
		do_close();
        (*m_rev_callback)(ACTCP_STAT_DISCONNECT,NULL);
	}
}

void ACTCP_ConfIpcClient::do_write(ACTCP_Message* pMsg  )
{
	bool write_in_progress = !m_write_msgs.empty();
	m_write_msgs.push_back(pMsg);
	if (!write_in_progress)
	{
		ACTCP_Message * msg_ptr = m_write_msgs.front();
		boost::asio::async_write(m_socket,
			boost::asio::buffer(msg_ptr->cBuffer,msg_ptr->nLen),
			boost::bind(&ACTCP_ConfIpcClient::handle_write, this,
			boost::asio::placeholders::error));
	}
}

void ACTCP_ConfIpcClient::handle_reading( const boost::system::error_code& error ,size_t bytes_transferred)
{
	if (!error)
	{
        if(bytes_transferred){
            (*m_rev_callback)((int)bytes_transferred,m_cReadingBuffer);
        }
        
        boost::asio::async_read(m_socket,boost::asio::buffer(m_cReadingBuffer, ACTCP_Reading_Buffer_Len),
                                boost::bind(&ACTCP_ConfIpcClient::handle_reading, this,
                                            boost::asio::placeholders::error,
                                            boost::asio::placeholders::bytes_transferred));
        //一旦收到数据或出错，就调用handler_read_response
	}
	else
	{
		do_close();
        (*m_rev_callback)(ACTCP_STAT_DISCONNECT,NULL);
	}
}



void ACTCP_ConfIpcClient::handle_connect( const boost::system::error_code& error )
{
	if (!error)
	{
        (*m_rev_callback)(ACTCP_STAT_CONNECTED,NULL);
        //读取
        handle_reading(error,0);
	}
	else
	{
        (*m_rev_callback)(ACTCP_STAT_CONNECT_FAILED,NULL);
	}
}

void ACTCP_ConfIpcClient::SendMsg( const unsigned char* pBuffer,int nBufferLen )
{
    ACTCP_Message* pMsg = (ACTCP_Message*)new char[sizeof(ACTCP_Message)+nBufferLen];
    pMsg->nLen = nBufferLen;
    memcpy(pMsg->cBuffer,pBuffer,nBufferLen);
	m_io_service.post(boost::bind(&ACTCP_ConfIpcClient::do_write, this, pMsg ));
	//do_write( msg.Clone() );
}

void ACTCP_ConfIpcClient::Close()
{
	m_io_service.post(boost::bind(&ACTCP_ConfIpcClient::do_close, this));
}

void ACTCP_ConfIpcClient::SetCallback( RevCallback callback )
{
	m_rev_callback = callback;
}
