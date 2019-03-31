#pragma once
#include <boost/bind.hpp>
#include <boost/asio.hpp>
#include <boost/thread/thread.hpp>
#include <cstdlib>
#include <deque>
#include <boost/scoped_array.hpp>

using boost::asio::ip::tcp;

#define ACTCP_Reading_Buffer_Len    1024

struct ACTCP_Message{
    int     nLen;
    char    cBuffer[4];
};

enum ACTCP_STAT{
    ACTCP_STAT_CONNECTED    =   0,
    ACTCP_STAT_CONNECT_FAILED = -1,
    ACTCP_STAT_DISCONNECT = -2
};

class ACTCP_ConfIpcClient
{
public:
	typedef std::deque<ACTCP_Message*> message_queue;
	typedef void (*RevCallback)( int nLen,const char* pMsg);
public:
	ACTCP_ConfIpcClient(boost::asio::io_service & io_service,
		tcp::endpoint & ed );
	~ACTCP_ConfIpcClient(void);
public:
	void Start();
	void Close();
//	void SendMsg( ACTCP_Message& msg );
    void SendMsg( const unsigned char* pBuffer,int nBufferLen );
	void SetCallback(  RevCallback callback );
private:
	  void handle_connect(const boost::system::error_code& error);
	  void handle_reading(const boost::system::error_code& error,size_t bytes_transferred);
	  void do_write( ACTCP_Message* pMsg );
	  void handle_write(const boost::system::error_code& error);
	  void do_close();
private:
	boost::asio::io_service&     m_io_service;
	tcp::socket				     m_socket;
	tcp::endpoint                m_endpoint;
	//ConfMessage                  m_read_msg;
	message_queue			     m_write_msgs;
    
    char                         m_cReadingBuffer[ACTCP_Reading_Buffer_Len];

//	int                          m_body_size;
//	boost::scoped_array<char>    m_read_body;
	RevCallback                  m_rev_callback;
};
