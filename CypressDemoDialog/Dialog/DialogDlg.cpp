
// DialogDlg.cpp: 实现文件
//

#include "pch.h"
#include "framework.h"
#include "Dialog.h"
#include "DialogDlg.h"
#include "afxdialogex.h"
#include <dbt.h>
#include "CyAPI.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif

#define     MAX_QUEUE_SZ                        64
#define     TIMEOUT_PER_TRANSFER_MILLI_SEC      1500

#define USBD_STATUS_ENDPOINT_HALTED     0xC0000030

// 用于应用程序“关于”菜单项的 CAboutDlg 对话框

class CAboutDlg : public CDialogEx
{
public:
	CAboutDlg();

// 对话框数据
#ifdef AFX_DESIGN_TIME
	enum { IDD = IDD_ABOUTBOX };
#endif

	protected:
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV 支持

// 实现
protected:
	DECLARE_MESSAGE_MAP()
};

CAboutDlg::CAboutDlg() : CDialogEx(IDD_ABOUTBOX)
{
}

void CAboutDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialogEx::DoDataExchange(pDX);
}

BEGIN_MESSAGE_MAP(CAboutDlg, CDialogEx)
END_MESSAGE_MAP()


// CDialogDlg 对话框
#define TOTAL_DL_NUM_18 18
#define TOTAL_DL_NUM_36 36
#define DATA_SHOW_LENGTH 1000
#define DATA_PAGE_LENGTH 1024
#define IDTIMER1 1
#define IDTIMER2 2

unsigned short g_xBuff[DATA_SHOW_LENGTH] = { 0 };
long g_yBuff[DATA_SHOW_LENGTH] = { 0 };
double XValues[DATA_SHOW_LENGTH] = { 0 };
double YValues[DATA_SHOW_LENGTH] = { 0 };
UCHAR g_buffersTrigResult[DATA_PAGE_LENGTH] = { 0 };
bool g_bKInstructionSend = FALSE;
int g_daoLianIndex = 16;
bool g_bButtonUSBTrigClicked = FALSE;
bool g_bButtonUARTTrigClicked = FALSE;
int g_writeIndex = 0;
//int g_saveIndex = 0;
int g_frameNumber = 32767;
bool g_frameCheakStart = FALSE; // FPGA外，USB FIFO中可能存有一帧数据，所以需要从第二帧开始校验
UCHAR g_triggerValue = 0x31;
UCHAR g_uartTrigValue = 0x31;
UINT g_samplingRate = 24000;
CString g_daoLianName[36] = {
	"FP1",
	"FP2",
	"F3",
	"FZ",
	"F4",
	"C3",
	"CZ",
	"C4",
	"T7",
	"T8",
	"P3",
	"PZ",
	"P4",
	"O1",
	"OZ",
	"O2",
	"F7",
	"F8",
	"FT7",
	"FC3",
	"FCZ",
	"FC4",
	"FT8",
	"TP7",
	"CP3",
	"CPZ",
	"CP4",
	"TP8",
	"P7",
	"P8",
	"VEOG",
	"HEOG",
	"S1",
	"S2",
	"S3",
	"S4"
};

namespace {
	UCHAR INT2ASCII(int n)
	{
		if (n < 10)
		{
			return 0x30 + n;
		}
		else if (n < 16)
		{
			return 'A' + n - 10;
		}
		return -1;
	}

	int ASCII2INT(UCHAR ascii)
	{
		if ((ascii >= '0') && (ascii <= '9'))
		{
			return ascii - '0';
		}
		else if ((ascii >= 'A') && (ascii <= 'Z'))
		{
			return ascii - 'A' + 10;
		}
		else if ((ascii >= 'a') && (ascii <= 'a'))
		{
			return ascii - 'a' + 10;
		}
		return -1;
	}

	UCHAR g_atParameter[100] = { 0 };
	long g_atParameterLength = 0;
	UCHAR g_atInstruction[100] = { 0 };
	long g_atInstructionLength = 0;

	void BuildAtParameterSampleRate(UINT samplingRate)
	{
		g_atParameterLength = 12;
		memset(g_atParameter, 0, sizeof(g_atParameter));
		sprintf((char*)g_atParameter, "0002%08X", samplingRate);
	}

	void BuildAtParameterTriggerValue(UCHAR value)
	{
		g_atParameterLength = 12;
		memset(g_atParameter, 0, sizeof(g_atParameter));
		sprintf((char*)g_atParameter, "0003%08X", value);
	}

	void BuildAtParameterDlNum(UINT dlNum)
	{
		g_atParameterLength = 12;
		memset(g_atParameter, 0, sizeof(g_atParameter));
		if (dlNum != 0)
		{
			sprintf((char*)g_atParameter, "00050000%d%03d", 1, dlNum);
		}
		else
		{
			sprintf((char*)g_atParameter, "00050000%d%03d", 0, dlNum);
		}
	}

	void BuildAtParameterSampleRateEx()
	{
		g_atParameterLength = 25;
		memset(g_atParameter, 0, sizeof(g_atParameter));
		UINT triggerLength = 0x320;
		UINT samplingRateEx = 48000000 / g_samplingRate;
		sprintf((char*)g_atParameter, "%02X%02X12345678%08X876FC", samplingRateEx & 0xff, (samplingRateEx >> 8) & 0xff, triggerLength);
	}

	void BuildAtParameterStop()
	{
		g_atParameterLength = 1;
		memset(g_atParameter, 0, sizeof(g_atParameter));
		g_atParameter[0] = 0x30;
	}

	void BuildAtParameterQuery()
	{
		g_atParameterLength = 1;
		memset(g_atParameter, 0, sizeof(g_atParameter));
		g_atParameter[0] = 0x30;
	}

	void BuildAtParameterUartRead()
	{
		g_atParameterLength = 1;
		memset(g_atParameter, 0, sizeof(g_atParameter));
		g_atParameter[0] = 0x78;		// x
	}

	void BuildAtParameterUartWrite(CString write)
	{
		g_atParameterLength = 12;
		memset(g_atParameter, 0, sizeof(g_atParameter));
		sprintf((char*)g_atParameter, "%08d%04d", atoi(write.Mid(0, 8)), atoi(write.Mid(8, 4)));
	}

	void BuildAtParameterUartTrig(UCHAR value)
	{
		g_atParameterLength = 2;
		memset(g_atParameter, 0, sizeof(g_atParameter));
		sprintf((char*)g_atParameter, "%02d", value);
	}

	void BuildAtParameterTotalDlNum(UCHAR totalDlNum)
	{
		g_atParameterLength = 2;
		memset(g_atParameter, 0, sizeof(g_atParameter));
		sprintf((char*)g_atParameter, "%02x", totalDlNum);
	}

	void BuildAtInstruction(UCHAR cmdByte)
	{
		int i;
		unsigned char chAt = 0x40;		// @
		unsigned char chAnd = 0x26;		// &
		unsigned char chSharp = 0x23;	// #
		unsigned char check = 0;

		memset(g_atInstruction, 0, sizeof(g_atInstruction));

		g_atInstruction[0] = chAt;				// start flag
		g_atInstruction[1] = cmdByte;			// command

		memcpy(&g_atInstruction[2], g_atParameter, g_atParameterLength);

		check = cmdByte;
		for (i = 0; i < g_atParameterLength; i++)
		{
			check += g_atParameter[i];
		}

		g_atInstruction[2 + g_atParameterLength] = INT2ASCII(check >> 4);
		g_atInstruction[2 + g_atParameterLength + 1] = INT2ASCII(check & 0x0f);
		g_atInstruction[2 + g_atParameterLength + 2] = chAnd;				// repeat flag

		memcpy(&g_atInstruction[2 + g_atParameterLength + 3], &g_atInstruction[1], g_atParameterLength + 1 + 2);

		g_atInstruction[2 + (g_atParameterLength + 1 + 2) * 2] = chSharp;		// end flag
		g_atInstruction[2 + (g_atParameterLength + 1 + 2) * 2 + 1] = 0x30;		// add 0 to even number
		g_atInstructionLength = 2 + (g_atParameterLength + 1 + 2) * 2 + 2;
	}

	void ImpedanceRow(UCHAR uDlNum, PUCHAR* buffersInput, CString & strTemp)
	{
		UCHAR buffersStart = 48 + (uDlNum - 1) * 4;
		UCHAR buffersEnd = 48 + uDlNum * 4 - 1;
		UINT impedanceCode = 0;
		impedanceCode += buffersInput[0][buffersStart] << 24;
		impedanceCode += buffersInput[0][buffersStart + 1] << 16;
		impedanceCode += buffersInput[0][buffersStart + 2] << 8;
		impedanceCode += buffersInput[0][buffersStart + 3];
		impedanceCode = impedanceCode >> 4;
		impedanceCode = impedanceCode - 0x8000000;
		impedanceCode = (impedanceCode < 0) ? 0 : impedanceCode;

		double impedance = 0.0f;
		if (uDlNum <= 32)
		{
			impedance = ((impedanceCode * 2500.0) / pow(2, 27)) / 4.3;
		}
		else
		{
			impedance = ((impedanceCode * 2500.0) / pow(2, 27)) / 2.15;
		}
		strTemp.Format("buffers[%03d-%03d]  -  \"%02X  %02X  %02X  %02X\"  -  %s, %02d/36, \t-  %.1fkΩ." \
			, buffersStart, buffersEnd
			, buffersInput[0][buffersStart], buffersInput[0][buffersStart + 1], buffersInput[0][buffersStart + 2], buffersInput[0][buffersStart + 3]
			, g_daoLianName[uDlNum - 1], uDlNum, impedance);
	}
}

CDialogDlg::CDialogDlg(CWnd* pParent /*=nullptr*/)
	: CDialogEx(IDD_DIALOG_DIALOG, pParent)
{
	m_hIcon = AfxGetApp()->LoadIcon(IDR_MAINFRAME);
	m_selectedUSBDevice = NULL;
	m_strEndPointEnumerate0x02 = _T("");
	m_strEndPointEnumerate0x04 = _T("");
	m_strEndPointEnumerate0x86 = _T("");
	m_strEndPointEnumerate0x88 = _T("");
	m_bButtonADCSampleClicked = FALSE;
	m_bButtonImpedanceClicked = FALSE;
	m_bADCInitiateComplete = TRUE;
	m_uDlNum = 0;
}

CDialogDlg::~CDialogDlg()
{
	if (m_selectedUSBDevice)
	{
		if (m_selectedUSBDevice->IsOpen()) m_selectedUSBDevice->Close();
		delete m_selectedUSBDevice;
	}
}

void CDialogDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialogEx::DoDataExchange(pDX);
	DDX_Control(pDX, IDC_COMBO_DEVICES, m_comboDevices);
	DDX_Control(pDX, IDC_BUTTON_VERSION, m_buttonVersion);
	DDX_Control(pDX, IDC_BUTTON_ADC_SAMPLE, m_buttonADCSample);
	DDX_Control(pDX, IDC_CUSTOM_SHOW, m_ChartCtrl);
	DDX_Control(pDX, IDC_BUTTON_SET_SAMPLE_FREQ, m_buttonSetSampleFreq);
	DDX_Control(pDX, IDC_EDIT_QUERY_RESULT, m_edtQueryResult);
	DDX_Control(pDX, IDC_EDIT_SAMPLE_FREQ, m_edtSampleFreq);
	DDX_Control(pDX, IDC_BUTTON_TRIGGER, m_buttonUSBTrig);
	DDX_Control(pDX, IDC_EDIT_TRIG_VALUE, m_edtTriggerValue);
	DDX_Control(pDX, IDC_EDIT_UART_TRIG, m_edtUartTrigValue);
	DDX_Control(pDX, IDC_EDIT_IMPEDANCE, m_edtImpedance);
	DDX_Control(pDX, IDC_COMBO_PORT_Nr, m_PortNr);
	DDX_Control(pDX, IDC_EDIT_PRODUCT_ID, m_edtProductId);
	DDX_Control(pDX, IDC_BUTTON_UART_TRIG, m_buttonUARTTrig);
	DDX_Control(pDX, IDC_CHECK_18_DL_NUM, m_buttonCheck18DlNum);
	DDX_Control(pDX, IDC_CHECK_IMPEDANCE, m_buttonCheckImpedance);
	DDX_Control(pDX, IDC_EDIT_ANALYSIS, m_edtAnalysis);
}

BEGIN_MESSAGE_MAP(CDialogDlg, CDialogEx)
	ON_WM_SYSCOMMAND()
	ON_WM_PAINT()
	ON_WM_QUERYDRAGICON()
	ON_CBN_SELCHANGE(IDC_COMBO_DEVICES, &CDialogDlg::OnCbnSelchangeComboDevices)
	ON_BN_CLICKED(IDC_BUTTON_VERSION, &CDialogDlg::OnBnClickedButtonStatus)
	ON_BN_CLICKED(IDC_BUTTON_ADC_SAMPLE, &CDialogDlg::OnBnClickedButtonAdcSample)
	ON_WM_TIMER()
	ON_BN_CLICKED(IDC_BUTTON_SET_SAMPLE_FREQ, &CDialogDlg::OnBnClickedButtonSetSampleFreq)
	ON_BN_CLICKED(IDC_BUTTON_TRIGGER, &CDialogDlg::OnBnClickedButtonTrigger)
	ON_BN_CLICKED(IDC_BUTTON_SEND, &CDialogDlg::OnBnClickedButtonSend)
	ON_BN_CLICKED(IDC_BUTTON_UART_TRIG, &CDialogDlg::OnBnClickedButtonUartTrig)
	ON_BN_CLICKED(IDC_CHECK_18_DL_NUM, &CDialogDlg::OnBnClickedCheck18DlNum)
	ON_BN_CLICKED(IDC_CHECK_IMPEDANCE, &CDialogDlg::OnBnClickedCheckImpedance)
END_MESSAGE_MAP()

// CDialogDlg 消息处理程序

BOOL CDialogDlg::OnInitDialog()
{
	CDialogEx::OnInitDialog();

	// 将“关于...”菜单项添加到系统菜单中。

	// IDM_ABOUTBOX 必须在系统命令范围内。
	ASSERT((IDM_ABOUTBOX & 0xFFF0) == IDM_ABOUTBOX);
	ASSERT(IDM_ABOUTBOX < 0xF000);

	CMenu* pSysMenu = GetSystemMenu(FALSE);
	if (pSysMenu != nullptr)
	{
		BOOL bNameValid;
		CString strAboutMenu;
		bNameValid = strAboutMenu.LoadString(IDS_ABOUTBOX);
		ASSERT(bNameValid);
		if (!strAboutMenu.IsEmpty())
		{
			pSysMenu->AppendMenu(MF_SEPARATOR);
			pSysMenu->AppendMenu(MF_STRING, IDM_ABOUTBOX, strAboutMenu);
		}
	}

	// 设置此对话框的图标。  当应用程序主窗口不是对话框时，框架将自动
	//  执行此操作
	SetIcon(m_hIcon, TRUE);			// 设置大图标
	SetIcon(m_hIcon, FALSE);		// 设置小图标

	// TODO: 在此添加额外的初始化代码
	CChartStandardAxis* pBottomAxis =
		m_ChartCtrl.CreateStandardAxis(CChartCtrl::BottomAxis);
	pBottomAxis->SetMinMax(0, DATA_SHOW_LENGTH);
	CChartStandardAxis* pLeftAxis =
		m_ChartCtrl.CreateStandardAxis(CChartCtrl::LeftAxis);
	pLeftAxis->SetMinMax(-1000, 1000);
	//CChartStandardAxis* pTopAxis =
	//	m_ChartCtrl.CreateStandardAxis(CChartCtrl::TopAxis);
	//pTopAxis->SetMinMax(0, DATA_SHOW_LENGTH);
	//CChartStandardAxis* pRightAxis =
	//	m_ChartCtrl.CreateStandardAxis(CChartCtrl::RightAxis);
	//pRightAxis->SetMinMax(-1000, 1000);
	pLineSeries = m_ChartCtrl.CreateLineSerie(false, false);

	m_selectedUSBDevice = new CCyUSBDevice(this->m_hWnd, CYUSBDRV_GUID, true);
	this->m_buttonADCSample.EnableWindow(FALSE);
	this->m_buttonUSBTrig.EnableWindow(FALSE);
	this->m_buttonUARTTrig.EnableWindow(FALSE);
	this->m_buttonVersion.EnableWindow(FALSE);
	this->m_buttonCheck18DlNum.EnableWindow(FALSE);
	this->m_buttonSetSampleFreq.EnableWindow(FALSE);
	this->m_buttonCheckImpedance.EnableWindow(FALSE);

	SurveyExistingDevices();
	EnumerateEndpointForTheSelectedDevice();

	UpdateData(FALSE);
	DoUpdateADCInitiateStatus();

	DataBuffInit();
	m_AxisMin = 32400;
	m_AxisMax = 34800;
	ChartCtrlInit();

	SurveyExistingComm();
	m_SerialPort.connectReadEvent(this);

	return TRUE;  // 除非将焦点设置到控件，否则返回 TRUE
}

void CDialogDlg::OnSysCommand(UINT nID, LPARAM lParam)
{
	if ((nID & 0xFFF0) == IDM_ABOUTBOX)
	{
		CAboutDlg dlgAbout;
		dlgAbout.DoModal();
	}
	else
	{
		CDialogEx::OnSysCommand(nID, lParam);
	}
}

// 如果向对话框添加最小化按钮，则需要下面的代码
//  来绘制该图标。  对于使用文档/视图模型的 MFC 应用程序，
//  这将由框架自动完成。

void CDialogDlg::OnPaint()
{
	if (IsIconic())
	{
		CPaintDC dc(this); // 用于绘制的设备上下文

		SendMessage(WM_ICONERASEBKGND, reinterpret_cast<WPARAM>(dc.GetSafeHdc()), 0);

		// 使图标在工作区矩形中居中
		int cxIcon = GetSystemMetrics(SM_CXICON);
		int cyIcon = GetSystemMetrics(SM_CYICON);
		CRect rect;
		GetClientRect(&rect);
		int x = (rect.Width() - cxIcon + 1) / 2;
		int y = (rect.Height() - cyIcon + 1) / 2;

		// 绘制图标
		dc.DrawIcon(x, y, m_hIcon);
	}
	else
	{
		CDialogEx::OnPaint();
	}
}

//当用户拖动最小化窗口时系统调用此函数取得光标
//显示。
HCURSOR CDialogDlg::OnQueryDragIcon()
{
	return static_cast<HCURSOR>(m_hIcon);
}

void CDialogDlg::OnCbnSelchangeComboDevices()
{
	// TODO: 在此添加控件通知处理程序代码
}

LRESULT CDialogDlg::DefWindowProc(UINT message, WPARAM wParam, LPARAM lParam)
{
	// TODO: 在此添加专用代码和/或调用基类
	if (message == WM_DEVICECHANGE && wParam >= DBT_DEVICEARRIVAL)
	{
		SurveyExistingComm();

		PDEV_BROADCAST_HDR lpdb = (PDEV_BROADCAST_HDR)lParam;
		if (wParam == DBT_DEVICEARRIVAL && lpdb->dbch_devicetype == DBT_DEVTYP_DEVICEINTERFACE)
		{
			SurveyExistingDevices();
			if (m_pThread == NULL) EnumerateEndpointForTheSelectedDevice();
		}
		else if (wParam == DBT_DEVICEREMOVECOMPLETE && lpdb->dbch_devicetype == DBT_DEVTYP_DEVICEINTERFACE)
		{
			SurveyExistingDevices();

			if (m_pThread == NULL) EnumerateEndpointForTheSelectedDevice();
		}
		lpdb->dbch_devicetype;
		lpdb->dbch_size;
	}

	return CDialogEx::DefWindowProc(message, wParam, lParam);
}

bool CDialogDlg::SurveyExistingDevices()
{
	CCyUSBDevice* USBDevice;
	USBDevice = new CCyUSBDevice(this->m_hWnd, CYUSBDRV_GUID, true);
	CString strDevice("");
	int nCboIndex = -1;
	if (m_comboDevices.GetCount() > 0) m_comboDevices.GetWindowText(strDevice);

	m_comboDevices.ResetContent();

	if (USBDevice != NULL)
	{
		int nInsertionCount = 0;
		int nDeviceCount = USBDevice->DeviceCount();
		for (int nCount = 0; nCount < nDeviceCount; nCount++)
		{
			CString strDeviceData;
			USBDevice->Open(nCount);
			strDeviceData.Format("(0x%04X - 0x%04X) %s", USBDevice->VendorID, USBDevice->ProductID, CString(USBDevice->FriendlyName));
			m_comboDevices.InsertString(nInsertionCount++, strDeviceData);
			if (nCboIndex == -1 && strDevice.IsEmpty() == FALSE && strDevice == strDeviceData)
				nCboIndex = nCount;

			USBDevice->Close();
		}
		delete USBDevice;
		if (m_comboDevices.GetCount() >= 1)
		{
			if (nCboIndex != -1) m_comboDevices.SetCurSel(nCboIndex);
			else m_comboDevices.SetCurSel(0);
		}
		SetFocus();
	}
	else return FALSE;

	return TRUE;
}

bool CDialogDlg::EnumerateEndpointForTheSelectedDevice()
{
	int nDeviceIndex = 0;

	// Is there any FX device connected to system?
	if ((nDeviceIndex = m_comboDevices.GetCurSel()) == -1 || m_selectedUSBDevice == NULL)
	{
		this->m_buttonADCSample.EnableWindow(FALSE);
		this->m_buttonUSBTrig.EnableWindow(FALSE);
		this->m_buttonUARTTrig.EnableWindow(FALSE);
		this->m_buttonVersion.EnableWindow(FALSE);
		this->m_buttonCheck18DlNum.EnableWindow(FALSE);
		this->m_buttonSetSampleFreq.EnableWindow(FALSE);
		this->m_buttonCheckImpedance.EnableWindow(FALSE);

		m_buttonADCSample.SetWindowText("正式启动");

		return FALSE;
	}

	// There are devices connected in the system.       
	m_selectedUSBDevice->Open(nDeviceIndex);
	int interfaces = this->m_selectedUSBDevice->AltIntfcCount() + 1;

	for (int nDeviceInterfaces = 0; nDeviceInterfaces < interfaces; nDeviceInterfaces++)
	{
		m_selectedUSBDevice->SetAltIntfc(nDeviceInterfaces);
		int eptCnt = m_selectedUSBDevice->EndPointCount();

		// Fill the EndPointsBox
		for (int endPoint = 1; endPoint < eptCnt; endPoint++)
		{
			CCyUSBEndPoint* ept = m_selectedUSBDevice->EndPoints[endPoint];

			// INTR, BULK and ISO endpoints are supported.
			if (ept->Attributes == 2)
			{
				CString strData(""), strTemp;

				strData += ((ept->Attributes == 1) ? "ISOC " : ((ept->Attributes == 2) ? "BULK " : "INTR "));
				strData += (ept->bIn ? "IN, " : "OUT, ");
				//strTemp.Format("%d  Bytes,", ept->MaxPktSize);
				//strData += strTemp;
				//
				//if(m_selectedUSBDevice->BcdUSB == USB30)
				//{
				//    strTemp.Format("%d  MaxBurst,", ept->ssmaxburst);
				//    strData += strTemp;
				//}

				strTemp.Format("AltInt - %d and EpAddr - 0x%02X", nDeviceInterfaces, ept->Address);
				strData += strTemp;

				if (endPoint == 1)
					m_strEndPointEnumerate0x02 = strData;
				if (endPoint == 2)
					m_strEndPointEnumerate0x04 = strData;
				if (endPoint == 3)
					m_strEndPointEnumerate0x86 = strData;
				if (endPoint == 4)
					m_strEndPointEnumerate0x88 = strData;
			}
		}
	}

	this->m_buttonADCSample.EnableWindow(TRUE);
	this->m_buttonUSBTrig.EnableWindow(FALSE);
	this->m_buttonUARTTrig.EnableWindow(FALSE);
	this->m_buttonVersion.EnableWindow(TRUE);
	this->m_buttonCheck18DlNum.EnableWindow(TRUE);
	this->m_buttonSetSampleFreq.EnableWindow(TRUE);
	this->m_buttonCheckImpedance.EnableWindow(TRUE);

	return TRUE;
}

void CDialogDlg::OnBnClickedButtonStatus()
{
	DoQuery();
}

void CDialogDlg::ConfigADCSamplingRate(UINT samplingRate)
{
	g_samplingRate = samplingRate;

	CString strOutData = m_strEndPointEnumerate0x02;
	TCHAR* pEnd;
	BYTE outEpAddress = 0x0;

	// Extract the endpoint addresses........
	strOutData = strOutData.Right(4);

	//outEpAddress = (BYTE)wcstoul(strOutData.GetBuffer(0), &pEnd, 16);
	outEpAddress = strtol(strOutData, &pEnd, 16);
	CCyUSBEndPoint* epBulkOut = m_selectedUSBDevice->EndPointOf(outEpAddress);

	if (epBulkOut == NULL) return;

	//
	// Get the max packet size (USB Frame Size).
	// For bulk burst transfer, this size represent bulk burst size.
	// Transfer size is now multiple USB frames defined by PACKETS_PER_TRANSFER
	//
	UCHAR QUEUE_SIZE = 1;
	UCHAR PACKETS_PER_TRANSFER = 1;
	long totalOutTransferSize = epBulkOut->MaxPktSize * PACKETS_PER_TRANSFER;
	epBulkOut->SetXferSize(totalOutTransferSize);

	OVERLAPPED  outOvLap;
	UCHAR* bufferOutput = new UCHAR[totalOutTransferSize];
	outOvLap.hEvent = CreateEvent(NULL, false, false, NULL);

	BuildAtParameterSampleRate(samplingRate);
	BuildAtInstruction('Z');

	for (int nCount = 0; nCount < g_atInstructionLength; nCount++)
	{
		bufferOutput[nCount] = g_atInstruction[nCount];
	}

	epBulkOut->TimeOut = TIMEOUT_PER_TRANSFER_MILLI_SEC;

	// Mark the start time
	/*SYSTEMTIME objStartTime;
	GetSystemTime(&objStartTime);*/

	epBulkOut->XferData(bufferOutput, g_atInstructionLength);

	// Bail out......
	delete[] bufferOutput;
	CloseHandle(outOvLap.hEvent);
}

void CDialogDlg::StartAdcSample()
{
	CString strOutData = m_strEndPointEnumerate0x02;
	TCHAR* pEnd;
	BYTE outEpAddress = 0x0;

	// Extract the endpoint addresses........
	strOutData = strOutData.Right(4);

	//outEpAddress = (BYTE)wcstoul(strOutData.GetBuffer(0), &pEnd, 16);
	outEpAddress = strtol(strOutData, &pEnd, 16);
	CCyUSBEndPoint* epBulkOut = m_selectedUSBDevice->EndPointOf(outEpAddress);

	if (epBulkOut == NULL) return;

	//
	// Get the max packet size (USB Frame Size).
	// For bulk burst transfer, this size represent bulk burst size.
	// Transfer size is now multiple USB frames defined by PACKETS_PER_TRANSFER
	//
	UCHAR QUEUE_SIZE = 1;
	UCHAR PACKETS_PER_TRANSFER = 1;
	long totalOutTransferSize = epBulkOut->MaxPktSize * PACKETS_PER_TRANSFER;
	epBulkOut->SetXferSize(totalOutTransferSize);

	OVERLAPPED  outOvLap;
	UCHAR* bufferOutput = new UCHAR[totalOutTransferSize];
	outOvLap.hEvent = CreateEvent(NULL, false, false, NULL);

	BuildAtParameterSampleRateEx();
	BuildAtInstruction('K');

	for (int nCount = 0; nCount < g_atInstructionLength; nCount++)
	{
		bufferOutput[nCount] = g_atInstruction[nCount];
	}

	epBulkOut->TimeOut = TIMEOUT_PER_TRANSFER_MILLI_SEC;

	// Mark the start time
	/*SYSTEMTIME objStartTime;
	GetSystemTime(&objStartTime);*/

	epBulkOut->XferData(bufferOutput, g_atInstructionLength);

	// Bail out......
	delete[] bufferOutput;
	CloseHandle(outOvLap.hEvent);
}

void CDialogDlg::StopAdcSample()
{
	g_frameCheakStart = FALSE;

	CString strOutData = m_strEndPointEnumerate0x02;
	TCHAR* pEnd;
	BYTE outEpAddress = 0x0;

	// Extract the endpoint addresses........
	strOutData = strOutData.Right(4);

	//outEpAddress = (BYTE)wcstoul(strOutData.GetBuffer(0), &pEnd, 16);
	outEpAddress = strtol(strOutData, &pEnd, 16);
	CCyUSBEndPoint* epBulkOut = m_selectedUSBDevice->EndPointOf(outEpAddress);

	if (epBulkOut == NULL) return;

	//
	// Get the max packet size (USB Frame Size).
	// For bulk burst transfer, this size represent bulk burst size.
	// Transfer size is now multiple USB frames defined by PACKETS_PER_TRANSFER
	//
	UCHAR QUEUE_SIZE = 1;
	UCHAR PACKETS_PER_TRANSFER = 1;
	long totalOutTransferSize = epBulkOut->MaxPktSize * PACKETS_PER_TRANSFER;
	epBulkOut->SetXferSize(totalOutTransferSize);

	OVERLAPPED  outOvLap;
	UCHAR* bufferOutput = new UCHAR[totalOutTransferSize];
	outOvLap.hEvent = CreateEvent(NULL, false, false, NULL);

	BuildAtParameterStop();
	BuildAtInstruction('M');

	for (int nCount = 0; nCount < g_atInstructionLength; nCount++)
	{
		bufferOutput[nCount] = g_atInstruction[nCount];
	}

	epBulkOut->TimeOut = TIMEOUT_PER_TRANSFER_MILLI_SEC;

	// Mark the start time
	/*SYSTEMTIME objStartTime;
	GetSystemTime(&objStartTime);*/

	epBulkOut->XferData(bufferOutput, g_atInstructionLength);

	// Bail out......
	delete[] bufferOutput;
	CloseHandle(outOvLap.hEvent);
}

void CDialogDlg::SendTriggerValue(UCHAR value)
{
	CString strOutData = m_strEndPointEnumerate0x02;
	TCHAR* pEnd;
	BYTE outEpAddress = 0x0;

	// Extract the endpoint addresses........
	strOutData = strOutData.Right(4);

	//outEpAddress = (BYTE)wcstoul(strOutData.GetBuffer(0), &pEnd, 16);
	outEpAddress = strtol(strOutData, &pEnd, 16);
	CCyUSBEndPoint* epBulkOut = m_selectedUSBDevice->EndPointOf(outEpAddress);

	if (epBulkOut == NULL) return;

	//
	// Get the max packet size (USB Frame Size).
	// For bulk burst transfer, this size represent bulk burst size.
	// Transfer size is now multiple USB frames defined by PACKETS_PER_TRANSFER
	//
	UCHAR QUEUE_SIZE = 1;
	UCHAR PACKETS_PER_TRANSFER = 1;
	long totalOutTransferSize = epBulkOut->MaxPktSize * PACKETS_PER_TRANSFER;
	epBulkOut->SetXferSize(totalOutTransferSize);

	OVERLAPPED  outOvLap;
	UCHAR* bufferOutput = new UCHAR[totalOutTransferSize];
	outOvLap.hEvent = CreateEvent(NULL, false, false, NULL);

	BuildAtParameterTriggerValue(value);
	BuildAtInstruction('Z');

	for (int nCount = 0; nCount < g_atInstructionLength; nCount++)
	{
		bufferOutput[nCount] = g_atInstruction[nCount];
	}

	epBulkOut->TimeOut = TIMEOUT_PER_TRANSFER_MILLI_SEC;

	// Mark the start time
	/*SYSTEMTIME objStartTime;
	GetSystemTime(&objStartTime);*/

	epBulkOut->XferData(bufferOutput, g_atInstructionLength);

	// Bail out......
	delete[] bufferOutput;
	CloseHandle(outOvLap.hEvent);
}

void CDialogDlg::SendUartTrigValue(UCHAR value)
{
	BuildAtParameterUartTrig(value);
	BuildAtInstruction('T');

	m_SerialPort.writeData(g_atInstruction, g_atInstructionLength);
}

void CDialogDlg::SendImpedanceInstruction(UINT dlNum)
{
	CString strOutData = m_strEndPointEnumerate0x02;
	TCHAR* pEnd;
	BYTE outEpAddress = 0x0;

	// Extract the endpoint addresses........
	strOutData = strOutData.Right(4);

	//outEpAddress = (BYTE)wcstoul(strOutData.GetBuffer(0), &pEnd, 16);
	outEpAddress = strtol(strOutData, &pEnd, 16);
	CCyUSBEndPoint* epBulkOut = m_selectedUSBDevice->EndPointOf(outEpAddress);

	if (epBulkOut == NULL) return;

	//
	// Get the max packet size (USB Frame Size).
	// For bulk burst transfer, this size represent bulk burst size.
	// Transfer size is now multiple USB frames defined by PACKETS_PER_TRANSFER
	//
	UCHAR QUEUE_SIZE = 1;
	UCHAR PACKETS_PER_TRANSFER = 1;
	long totalOutTransferSize = epBulkOut->MaxPktSize * PACKETS_PER_TRANSFER;
	epBulkOut->SetXferSize(totalOutTransferSize);

	OVERLAPPED  outOvLap;
	UCHAR* bufferOutput = new UCHAR[totalOutTransferSize];
	outOvLap.hEvent = CreateEvent(NULL, false, false, NULL);

	BuildAtParameterDlNum(dlNum);
	BuildAtInstruction('Z');

	for (int nCount = 0; nCount < g_atInstructionLength; nCount++)
	{
		bufferOutput[nCount] = g_atInstruction[nCount];
	}

	epBulkOut->TimeOut = TIMEOUT_PER_TRANSFER_MILLI_SEC;

	// Mark the start time
	/*SYSTEMTIME objStartTime;
	GetSystemTime(&objStartTime);*/

	epBulkOut->XferData(bufferOutput, g_atInstructionLength);

	// Bail out......
	delete[] bufferOutput;
	CloseHandle(outOvLap.hEvent);
}

DWORD CDialogDlg::ClearUSBFIFO()
{
	CString strINData = m_strEndPointEnumerate0x86;
	TCHAR* pEnd;
	BYTE inEpAddress = 0x0;

	// Extract the endpoint addresses........
	strINData = strINData.Right(4);

	//inEpAddress = (BYTE)wcstoul(strINData.GetBuffer(0), &pEnd, 16);
	inEpAddress = strtol(strINData, &pEnd, 16);
	CCyUSBEndPoint* epBulkIn = m_selectedUSBDevice->EndPointOf(inEpAddress);

	if (epBulkIn == NULL) return -1;

	//
	// Get the max packet size (USB Frame Size).
	// For bulk burst transfer, this size represent bulk burst size.
	// Transfer size is now multiple USB frames defined by PACKETS_PER_TRANSFER
	//
	UCHAR QUEUE_SIZE = 16;
	//UCHAR PACKETS_PER_TRANSFER = 2;
	long totalTransferSize = epBulkIn->MaxPktSize * 2;
	epBulkIn->SetXferSize(totalTransferSize);

	PUCHAR* buffersInput = new PUCHAR[QUEUE_SIZE];
	PUCHAR* contextsInput = new PUCHAR[QUEUE_SIZE];
	OVERLAPPED		inOvLap[MAX_QUEUE_SZ];

	// Allocate all the buffers for the queues
	for (int nCount = 0; nCount < QUEUE_SIZE; nCount++)
	{
		buffersInput[nCount] = new UCHAR[totalTransferSize];
		inOvLap[nCount].hEvent = CreateEvent(NULL, false, false, NULL);

		memset(buffersInput[nCount], 0xEF, totalTransferSize);
	}

	// Queue-up the first batch of transfer requests
	for (int nCount = 0; nCount < QUEUE_SIZE; nCount++)
	{
		////////////////////BeginDataXFer will kick start the IN transactions.................
		contextsInput[nCount] = epBulkIn->BeginDataXfer(buffersInput[nCount], totalTransferSize, &inOvLap[nCount]);
		if (epBulkIn->NtStatus || epBulkIn->UsbdStatus)
		{

			if (epBulkIn->UsbdStatus == USBD_STATUS_ENDPOINT_HALTED)
			{
				epBulkIn->Reset();
				epBulkIn->Abort();
				Sleep(50);
				contextsInput[nCount] = epBulkIn->BeginDataXfer(buffersInput[nCount], totalTransferSize, &inOvLap[nCount]);

			}
			if (epBulkIn->NtStatus || epBulkIn->UsbdStatus)
			{
				// BeginDataXfer failed
				// Handle the error now.
				epBulkIn->Abort();
				for (int j = 0; j < QUEUE_SIZE; j++)
				{
					CloseHandle(inOvLap[j].hEvent);
					delete[] buffersInput[j];
				}

				// Bail out......
				delete[]contextsInput;
				delete[] buffersInput;
				CString strMsg;
				strMsg.Format("BeginDataXfer Failed with (NT Status = 0x%X and USBD Status = 0x%X). Bailing out...", epBulkIn->NtStatus, epBulkIn->UsbdStatus);
				AfxMessageBox(strMsg);
				return -2;
			}
		}
	}

	long nCount = 0;

	long readLength = totalTransferSize;

	//////////Wait till the transfer completion..///////////////////////////
	if (!epBulkIn->WaitForXfer(&inOvLap[nCount], TIMEOUT_PER_TRANSFER_MILLI_SEC))
	{
		//epBulkIn->Abort();
		//if (epBulkIn->LastError == ERROR_IO_PENDING)
		//	WaitForSingleObject(inOvLap[nCount].hEvent, TIMEOUT_PER_TRANSFER_MILLI_SEC);

		//epBulkIn->Reset();
		//Sleep(50);
		m_selectedUSBDevice->Reset();
		Sleep(TIMEOUT_PER_TRANSFER_MILLI_SEC);
		return -2;
	}

	////////////Read the trasnferred data from the device///////////////////////////////////////
	epBulkIn->FinishDataXfer(buffersInput[nCount], readLength, &inOvLap[nCount], contextsInput[nCount]);

	// Re-submit this queue element to keep the queue full
	contextsInput[nCount] = epBulkIn->BeginDataXfer(buffersInput[nCount], totalTransferSize, &inOvLap[nCount]);
	if (epBulkIn->NtStatus || epBulkIn->UsbdStatus)
	{
		// BeginDataXfer failed............
		// Time to bail out now............
		epBulkIn->Abort();
		for (int j = 0; j < QUEUE_SIZE; j++)
		{
			CloseHandle(inOvLap[j].hEvent);
			delete[] buffersInput[j];
		}
		delete[]contextsInput;

		CString strMsg;
		strMsg.Format("BeginDataXfer Failed during buffer re-cycle (NT Status = 0x%X and USBD Status = 0x%X). Bailing out...", epBulkIn->NtStatus, epBulkIn->UsbdStatus);
		AfxMessageBox(strMsg);
		return -3;
	}
	if (++nCount >= QUEUE_SIZE)
	{
		nCount = 0;
	}

	epBulkIn->Abort();
	for (int j = 0; j < QUEUE_SIZE; j++)
	{
		CloseHandle(inOvLap[j].hEvent);
		delete[] buffersInput[j];
		delete[] contextsInput[j];
	}

	// Bail out......
	delete[]contextsInput;
	delete[] buffersInput;

	return 0;
}

void CDialogDlg::OnBnClickedButtonAdcSample()
{
	char ch1[10];
	GetDlgItem(IDC_EDIT_IMPEDANCE)->GetWindowText(ch1, 10);
	m_uDlNum = atoi(ch1);
	if ((m_uDlNum < 1) || (m_uDlNum > 144))
	{
		AfxMessageBox(_T("请确认输入了正确的导联号！！！"));
		return;
	}
	g_daoLianIndex = 16 + 4 * (m_uDlNum - 1);

	if (m_buttonCheckImpedance.GetCheck())
	{
		AfxMessageBox(_T("请先关闭阻抗检测！！！"));
		return;
	}

	if (m_bButtonADCSampleClicked == FALSE)
	{
		m_bButtonADCSampleClicked = TRUE;

		m_buttonADCSample.SetWindowText("停止");
		m_buttonUSBTrig.EnableWindow(TRUE);
		m_buttonUARTTrig.EnableWindow(TRUE);

		//ConfigADCSamplingRate(24000);
		StartAdcSample();

		m_pThread = AfxBeginThread((AFX_THREADPROC)PerformADCSampling, (LPVOID)this);

		SetTimer(IDTIMER1, 100, NULL);
	}
	else
	{
		m_bButtonADCSampleClicked = FALSE;
		g_bKInstructionSend = FALSE;

		m_buttonADCSample.SetWindowText("正式启动");
		m_buttonUSBTrig.EnableWindow(FALSE);
		m_buttonUARTTrig.EnableWindow(FALSE);

		WaitForSingleObject(m_pThread->m_hThread, 100);
		m_pThread = NULL;

		StopAdcSample();

		KillTimer(IDTIMER1);

		ClearUSBFIFO();
	}
}

DWORD WINAPI CDialogDlg::PerformADCSampling(LPVOID lParam)
{
	CDialogDlg* pThis = (CDialogDlg*)lParam;

	CString strINData = pThis->m_strEndPointEnumerate0x86;
	TCHAR* pEnd;
	BYTE inEpAddress = 0x0;

	// Extract the endpoint addresses........
	strINData = strINData.Right(4);

	//inEpAddress = (BYTE)wcstoul(strINData.GetBuffer(0), &pEnd, 16);
	inEpAddress = strtol(strINData, &pEnd, 16);
	CCyUSBEndPoint* epBulkIn = pThis->m_selectedUSBDevice->EndPointOf(inEpAddress);

	if (epBulkIn == NULL) return -1;

	//
	// Get the max packet size (USB Frame Size).
	// For bulk burst transfer, this size represent bulk burst size.
	// Transfer size is now multiple USB frames defined by PACKETS_PER_TRANSFER
	//
	UCHAR QUEUE_SIZE = 16;
	//UCHAR PACKETS_PER_TRANSFER = 2;
	long totalTransferSize = epBulkIn->MaxPktSize * 2;
	epBulkIn->SetXferSize(totalTransferSize);

	PUCHAR* buffersInput = new PUCHAR[QUEUE_SIZE];
	PUCHAR* contextsInput = new PUCHAR[QUEUE_SIZE];
	OVERLAPPED		inOvLap[MAX_QUEUE_SZ];

	// Allocate all the buffers for the queues
	for (int nCount = 0; nCount < QUEUE_SIZE; nCount++)
	{
		buffersInput[nCount] = new UCHAR[totalTransferSize];
		inOvLap[nCount].hEvent = CreateEvent(NULL, false, false, NULL);

		memset(buffersInput[nCount], 0xEF, totalTransferSize);
	}

	// Queue-up the first batch of transfer requests
	for (int nCount = 0; nCount < QUEUE_SIZE; nCount++)
	{
		////////////////////BeginDataXFer will kick start the IN transactions.................
		contextsInput[nCount] = epBulkIn->BeginDataXfer(buffersInput[nCount], totalTransferSize, &inOvLap[nCount]);
		if (epBulkIn->NtStatus || epBulkIn->UsbdStatus)
		{

			if (epBulkIn->UsbdStatus == USBD_STATUS_ENDPOINT_HALTED)
			{
				epBulkIn->Reset();
				epBulkIn->Abort();
				Sleep(50);
				contextsInput[nCount] = epBulkIn->BeginDataXfer(buffersInput[nCount], totalTransferSize, &inOvLap[nCount]);

			}
			if (epBulkIn->NtStatus || epBulkIn->UsbdStatus)
			{
				// BeginDataXfer failed
				// Handle the error now.
				epBulkIn->Abort();
				for (int j = 0; j < QUEUE_SIZE; j++)
				{
					CloseHandle(inOvLap[j].hEvent);
					delete[] buffersInput[j];
				}

				// Bail out......
				delete[]contextsInput;
				delete[] buffersInput;
				CString strMsg;
				strMsg.Format("BeginDataXfer Failed with (NT Status = 0x%X and USBD Status = 0x%X). Bailing out...", epBulkIn->NtStatus, epBulkIn->UsbdStatus);
				AfxMessageBox(strMsg);
				return -2;
			}
		}
	}

	// Mark the start time
	/*SYSTEMTIME objStartTime;
	GetSystemTime(&objStartTime);*/

	long nCount = 0;
	//FILE* fp = NULL;
	while (pThis->m_bButtonADCSampleClicked == TRUE)
	{
		//if ((fp == NULL) && (pThis->m_bButtonADCSampleClicked == TRUE))
		//{
		//	fp = fopen("../samples/data.txt", "w");
		//}

		long readLength = totalTransferSize;

		//////////Wait till the transfer completion..///////////////////////////
		if (!epBulkIn->WaitForXfer(&inOvLap[nCount], TIMEOUT_PER_TRANSFER_MILLI_SEC))
		{
			//epBulkIn->Abort();
			//if (epBulkIn->LastError == ERROR_IO_PENDING)
			//	WaitForSingleObject(inOvLap[nCount].hEvent, TIMEOUT_PER_TRANSFER_MILLI_SEC);

			//epBulkIn->Reset();
			//Sleep(50);
			pThis->m_selectedUSBDevice->Reset();
			Sleep(TIMEOUT_PER_TRANSFER_MILLI_SEC);
			break;
		}

		////////////Read the trasnferred data from the device///////////////////////////////////////
		epBulkIn->FinishDataXfer(buffersInput[nCount], readLength, &inOvLap[nCount], contextsInput[nCount]);

		//for (int mCount = 0; mCount < readLength; mCount++)
		//{
		//	fprintf(fp, "%02X", buffersInput[nCount][mCount]);

		//	if (g_saveIndex + 1 == DATA_PAGE_LENGTH)
		//	{
		//		fprintf(fp, "\r");
		//	}
		//	else
		//	{
		//		fprintf(fp, "  ");
		//	}
		//	
		//	g_saveIndex = (g_saveIndex + 1) % DATA_PAGE_LENGTH;
		//}

		int frameNumber = 0;
		frameNumber += buffersInput[nCount][4] << 24;
		frameNumber += buffersInput[nCount][5] << 16;
		frameNumber += buffersInput[nCount][6] << 8;
		frameNumber += buffersInput[nCount][7];

		if ((frameNumber == 0) && (!g_frameCheakStart))
		{
			g_frameCheakStart = TRUE;
			g_frameNumber = 32767;
		}

		if (((32768 + frameNumber - g_frameNumber) % 32768 != 1) && g_frameCheakStart)
		{
			CString strFrameNumberError;
			strFrameNumberError.Format("g_frameNumber not continuous: %d - %d!!", g_frameNumber, frameNumber);
			pThis->m_edtAnalysis.SetWindowText(strFrameNumberError);
		}

		g_frameNumber = frameNumber;

		if ((buffersInput[nCount][0] == 0xAA)
			&& (buffersInput[nCount][1] == 0x00)
			&& (buffersInput[nCount][2] == 0x00)
			&& ((buffersInput[nCount][3] == g_triggerValue) || (buffersInput[nCount][3] == g_uartTrigValue))
			&& ((g_bButtonUSBTrigClicked == TRUE) || (g_bButtonUARTTrigClicked == TRUE)))
		{
			for (int mCount = 0; mCount < readLength; mCount++)
			{
				g_buffersTrigResult[mCount] = buffersInput[nCount][mCount];
			}

			g_bButtonUSBTrigClicked = FALSE;
			g_bButtonUARTTrigClicked = FALSE;
		}

		g_yBuff[g_writeIndex] = buffersInput[nCount][g_daoLianIndex] << 20;
		g_yBuff[g_writeIndex] += buffersInput[nCount][g_daoLianIndex + 1] << 12;
		g_yBuff[g_writeIndex] += buffersInput[nCount][g_daoLianIndex + 2] << 4;
		g_yBuff[g_writeIndex] += buffersInput[nCount][g_daoLianIndex + 3] >> 4;
		g_yBuff[g_writeIndex] -= 0x8000000;

		g_writeIndex = (g_writeIndex + 1) % DATA_SHOW_LENGTH;

		//////////BytesXFerred is need for current data rate calculation.
		///////// Refer to CalculateTransferSpeed function for the exact
		///////// calculation.............................
		//if (BytesXferred < 0) // Rollover - reset counters
		//{
		//    BytesXferred = 0;
		//    GetSystemTime(&objStartTime);
		//}


		// Re-submit this queue element to keep the queue full
		contextsInput[nCount] = epBulkIn->BeginDataXfer(buffersInput[nCount], totalTransferSize, &inOvLap[nCount]);
		if (epBulkIn->NtStatus || epBulkIn->UsbdStatus)
		{
			// BeginDataXfer failed............
			// Time to bail out now............
			epBulkIn->Abort();
			for (int j = 0; j < QUEUE_SIZE; j++)
			{
				CloseHandle(inOvLap[j].hEvent);
				delete[] buffersInput[j];
			}
			delete[]contextsInput;

			CString strMsg;
			strMsg.Format("BeginDataXfer Failed during buffer re-cycle (NT Status = 0x%X and USBD Status = 0x%X). Bailing out...", epBulkIn->NtStatus, epBulkIn->UsbdStatus);
			AfxMessageBox(strMsg);
			return -3;
		}
		if (++nCount >= QUEUE_SIZE)
		{
			nCount = 0;
			//if ((pThis->m_bButtonADCSampleClicked == FALSE) && (fp != NULL))
			//{
			//	fclose(fp);
			//	fp = NULL;
			//}
		}
	}

	epBulkIn->Abort();
	for (int j = 0; j < QUEUE_SIZE; j++)
	{
		CloseHandle(inOvLap[j].hEvent);
		delete[] buffersInput[j];
		delete[] contextsInput[j];
	}

	// Bail out......
	delete[]contextsInput;
	delete[] buffersInput;

	return 0;
}

void CDialogDlg::OnTimer(UINT_PTR nIDEvent)
{
	switch (nIDEvent)
	{
	case IDTIMER1:
	{
		/* void CChartDemoDlg::OnAddseries() */
		pLineSeries->SetWidth(1);
		pLineSeries->SetPenStyle(0);
		pLineSeries->SetName(_T("波形"));
		pLineSeries->SetColor(255); //red
		for (int i = 0; i < DATA_SHOW_LENGTH; i++)
		{
			YValues[i] = (((g_yBuff[i] * 2500.0) / pow(2, 27)) / 3.57);
		}
		pLineSeries->SetPoints(XValues, YValues, DATA_SHOW_LENGTH);

		/* void CChartDemoDlg::OnAxisAutomaticCheck() */
		CChartAxis* pAxis = m_ChartCtrl.GetLeftAxis();

		double MinVal = YValues[0], MaxVal = YValues[0];
		for (int i = 0; i < DATA_SHOW_LENGTH; i++)
		{
			if (YValues[i] < MinVal)
			{
				MinVal = YValues[i];
			}
		}
		for (int i = 0; i < DATA_SHOW_LENGTH; i++)
		{
			if (YValues[i] > MaxVal)
			{
				MaxVal = YValues[i];
			}
		}

		pAxis->SetAutomatic(false);
		pAxis->SetMinMax(MinVal - (MaxVal - MinVal) / 10, MaxVal + (MaxVal - MinVal) / 10);

		m_ChartCtrl.RefreshCtrl();

		break;
	}
	case IDTIMER2:
	{
		DoQuery();

		break;
	}
	default:
		break;
	}

	CDialogEx::OnTimer(nIDEvent);
}

// 显示点数据包初始化
void CDialogDlg::DataBuffInit()
{
	// TODO: 在此处添加实现代码.
	for (int i = 0; i < DATA_SHOW_LENGTH; i++)
	{
		g_xBuff[i] = i + 1;

		XValues[i] = i + 1;
	}
}

// 初始化画图界面窗口
void CDialogDlg::ChartCtrlInit()
{

}

void CDialogDlg::DoQuery()
{
	CString strINData = m_strEndPointEnumerate0x88;
	CString strOutData = m_strEndPointEnumerate0x02;
	TCHAR* pEnd;
	BYTE inEpAddress = 0x0, outEpAddress = 0x0;

	// Extract the endpoint addresses........
	strINData = strINData.Right(4);
	strOutData = strOutData.Right(4);

	//inEpAddress = (BYTE)wcstoul(strINData.GetBuffer(0), &pEnd, 16);
	inEpAddress = strtol(strINData, &pEnd, 16);
	//outEpAddress = (BYTE)wcstoul(strOutData.GetBuffer(0), &pEnd, 16);
	outEpAddress = strtol(strOutData, &pEnd, 16);
	CCyUSBEndPoint* epBulkOut = m_selectedUSBDevice->EndPointOf(outEpAddress);
	CCyUSBEndPoint* epBulkIn = m_selectedUSBDevice->EndPointOf(inEpAddress);

	if (epBulkOut == NULL || epBulkIn == NULL) return;

	//
	// Get the max packet size (USB Frame Size).
	// For bulk burst transfer, this size represent bulk burst size.
	// Transfer size is now multiple USB frames defined by PACKETS_PER_TRANSFER
	//
	UCHAR QUEUE_SIZE = 1;
	//UCHAR PACKETS_PER_TRANSFER = 2;
	long totalTransferSize = epBulkIn->MaxPktSize * 2;
	epBulkIn->SetXferSize(totalTransferSize);

	long totalOutTransferSize = epBulkOut->MaxPktSize * 1;
	epBulkOut->SetXferSize(totalOutTransferSize);

	PUCHAR* buffersInput = new PUCHAR[QUEUE_SIZE];
	PUCHAR* contextsInput = new PUCHAR[QUEUE_SIZE];
	OVERLAPPED		inOvLap[MAX_QUEUE_SZ];

	// Allocate all the buffers for the queues
	for (int nCount = 0; nCount < QUEUE_SIZE; nCount++)
	{
		buffersInput[nCount] = new UCHAR[totalTransferSize];
		inOvLap[nCount].hEvent = CreateEvent(NULL, false, false, NULL);

		memset(buffersInput[nCount], 0xEF, totalTransferSize);
	}

	OVERLAPPED  outOvLap;
	UCHAR* bufferOutput = new UCHAR[totalOutTransferSize];
	outOvLap.hEvent = CreateEvent(NULL, false, false, NULL);

	BuildAtParameterQuery();
	BuildAtInstruction('R');

	for (int nCount = 0; nCount < g_atInstructionLength; nCount++)
	{
		bufferOutput[nCount] = g_atInstruction[nCount];
	}

	epBulkOut->TimeOut = TIMEOUT_PER_TRANSFER_MILLI_SEC;

	// Queue-up the first batch of transfer requests
	for (int nCount = 0; nCount < QUEUE_SIZE; nCount++)
	{
		////////////////////BeginDataXFer will kick start the IN transactions.................
		contextsInput[nCount] = epBulkIn->BeginDataXfer(buffersInput[nCount], totalTransferSize, &inOvLap[nCount]);
		if (epBulkIn->NtStatus || epBulkIn->UsbdStatus)
		{

			if (epBulkIn->UsbdStatus == USBD_STATUS_ENDPOINT_HALTED)
			{
				epBulkIn->Reset();
				epBulkIn->Abort();
				Sleep(50);
				contextsInput[nCount] = epBulkIn->BeginDataXfer(buffersInput[nCount], totalTransferSize, &inOvLap[nCount]);

			}
			if (epBulkIn->NtStatus || epBulkIn->UsbdStatus)
			{
				// BeginDataXfer failed
				// Handle the error now.
				epBulkIn->Abort();
				for (int j = 0; j < QUEUE_SIZE; j++)
				{
					CloseHandle(inOvLap[j].hEvent);
					delete[] buffersInput[j];
				}

				// Bail out......
				delete[]contextsInput;
				delete[] buffersInput;
				CString strMsg;
				strMsg.Format("BeginDataXfer Failed with (NT Status = 0x%X and USBD Status = 0x%X). Bailing out...", epBulkIn->NtStatus, epBulkIn->UsbdStatus);
				AfxMessageBox(strMsg);
				return;
			}
		}
	}

	// Mark the start time
	/*SYSTEMTIME objStartTime;
	GetSystemTime(&objStartTime);*/

	long nINCount = 0;
	while (nINCount < QUEUE_SIZE)
	{
		long readLength = totalTransferSize;

		epBulkOut->XferData(bufferOutput, g_atInstructionLength);

		//////////Wait till the transfer completion..///////////////////////////
		if (!epBulkIn->WaitForXfer(&inOvLap[nINCount], TIMEOUT_PER_TRANSFER_MILLI_SEC))
		{
			epBulkIn->Abort();
			if (epBulkIn->LastError == ERROR_IO_PENDING)
				WaitForSingleObject(inOvLap[nINCount].hEvent, TIMEOUT_PER_TRANSFER_MILLI_SEC);
		}

		////////////Read the trasnferred data from the device///////////////////////////////////////
		epBulkIn->FinishDataXfer(buffersInput[nINCount], readLength, &inOvLap[nINCount], contextsInput[nINCount]);

		CString strBytes(""), strTemp;
		for (int nCount = 0; nCount < readLength; nCount++)
		{
			if (nCount % 16 == 0)
			{
				strTemp.Format("%04X", nCount);
				strBytes += strTemp;
				strBytes += "    ";
			}

			strTemp.Format("%02X", buffersInput[0][nCount]);
			strBytes += strTemp;

			if ((nCount + 1) % 16 == 0)
			{
				strBytes += "\r\n";
			}
			else
			{
				strBytes += "  ";
			}
		}
		m_edtQueryResult.SetWindowText(strBytes);

		int impedanceTriggerSwitch = 0;
		impedanceTriggerSwitch += buffersInput[0][44] << 24;
		impedanceTriggerSwitch += buffersInput[0][45] << 16;
		impedanceTriggerSwitch += buffersInput[0][46] << 8;
		impedanceTriggerSwitch += buffersInput[0][47];

		CString strAnalysis("");
		if (impedanceTriggerSwitch)
		{
			int totalDlNum = 0;
			totalDlNum += buffersInput[0][20] << 24;
			totalDlNum += buffersInput[0][21] << 16;
			totalDlNum += buffersInput[0][22] << 8;
			totalDlNum += buffersInput[0][23];

			strAnalysis = _T("");
			if (totalDlNum == TOTAL_DL_NUM_18)
			{
				for (UINT t = 1; t <= TOTAL_DL_NUM_36; t = t + 2)
				{
					ImpedanceRow(t, buffersInput, strTemp);
					strAnalysis += strTemp;
					strAnalysis += "\r\n";
				}
			}

			if (totalDlNum == TOTAL_DL_NUM_36)
			{
				for (UINT t = 1; t <= TOTAL_DL_NUM_36; t++)
				{
					ImpedanceRow(t, buffersInput, strTemp);
					strAnalysis += strTemp;
					strAnalysis += "\r\n";
				}
			}

			m_edtAnalysis.SetWindowTextA(strAnalysis);
		}
		else
		{
			strAnalysis = _T("");
			strTemp.Format("buffers[04-07]  -  \"%02X  %02X  %02X  %02X\"\t-  ADC Initiated Success or Not." \
				, buffersInput[0][4], buffersInput[0][5], buffersInput[0][6], buffersInput[0][7]);
			strAnalysis += strTemp;
			strAnalysis += "\r\n";
			strTemp.Format("buffers[08-11]  -  \"%02X  %02X  %02X  %02X\"\t-  Amplifiler Product Date." \
				, buffersInput[0][8], buffersInput[0][9], buffersInput[0][10], buffersInput[0][11]);
			strAnalysis += strTemp;
			strAnalysis += "\r\n";
			strTemp.Format("buffers[12-15]  -  \"%02X  %02X  %02X  %02X\"\t-  Amplifiler Serial Number." \
				, buffersInput[0][12], buffersInput[0][13], buffersInput[0][14], buffersInput[0][15]);
			strAnalysis += strTemp;
			strAnalysis += "\r\n";
			strTemp.Format("buffers[16-19]  -  \"%02X  %02X  %02X  %02X\"\t-  FPGA Version." \
				, buffersInput[0][16], buffersInput[0][17], buffersInput[0][18], buffersInput[0][19]);
			strAnalysis += strTemp;
			strAnalysis += "\r\n";
			int totalDlNum = 0;
			totalDlNum += buffersInput[0][20] << 24;
			totalDlNum += buffersInput[0][21] << 16;
			totalDlNum += buffersInput[0][22] << 8;
			totalDlNum += buffersInput[0][23];
			strTemp.Format("buffers[20-23]  -  \"%02X  %02X  %02X  %02X\"\t-  18 DL Mode or 36 DL Mode, 0x12 = 18, 0x24 = 36." \
				, buffersInput[0][20], buffersInput[0][21], buffersInput[0][22], buffersInput[0][23]);
			strAnalysis += strTemp;
			strAnalysis += "\r\n";
			int samplePeriod = 0;
			samplePeriod += buffersInput[0][24] << 24;
			samplePeriod += buffersInput[0][25] << 16;
			samplePeriod += buffersInput[0][26] << 8;
			samplePeriod += buffersInput[0][27];
			int sampleFrequency = 48000000 / samplePeriod;
			if (totalDlNum == TOTAL_DL_NUM_18)
			{
				strTemp.Format("buffers[24-27]  -  \"%02X  %02X  %02X  %02X\"\t-  Sample Frequency, (48MHz/0x%X)*2 = %d(Hz)." \
					, buffersInput[0][24], buffersInput[0][25], buffersInput[0][26], buffersInput[0][27], samplePeriod, sampleFrequency * 2);
			}
			else
			{
				strTemp.Format("buffers[24-27]  -  \"%02X  %02X  %02X  %02X\"\t-  Sample Frequency, 48MHz/0x%X = %d(Hz)." \
					, buffersInput[0][24], buffersInput[0][25], buffersInput[0][26], buffersInput[0][27], samplePeriod, sampleFrequency);
			}
			strAnalysis += strTemp;
			strAnalysis += "\r\n";
			strTemp.Format("buffers[36-36]  -  \"%02X\"\t\t-  Battery Status, 0x00 = Normal, 0x01 = Charge Complete,\r\t\t\t\t\t\t   0x02 = Charging, 0x03 = Low Battery." \
				, buffersInput[0][36]);
			strAnalysis += strTemp;
			strAnalysis += "\r\n";
			strTemp.Format("buffers[37-37]  -  \"%02X\"\t\t-  Battery Level, 0x00 = 1 Grid, 0x01 = 2 Grid, 0x02 = 3 Grid,\r\t\t\t\t\t   0x03 = 4 Grid, 0x04 = 5 Grid." \
				, buffersInput[0][37]);
			strAnalysis += strTemp;
			strAnalysis += "\r\n";
			strTemp.Format("buffers[38-39]  -  \"%02X  %02X\"\t\t-  ADC Value Of Battery Level, 0x%02X%02X." \
				, buffersInput[0][38], buffersInput[0][39], buffersInput[0][38], buffersInput[0][39]);
			strAnalysis += strTemp;
			strAnalysis += "\r\n";
			strTemp.Format("buffers[40-43]  -  \"%02X  %02X  %02X  %02X\"\t-  Sampling Enabled or Disabled." \
				, buffersInput[0][40], buffersInput[0][41], buffersInput[0][42], buffersInput[0][43]);
			strAnalysis += strTemp;
			strAnalysis += "\r\n";
			strTemp.Format("buffers[44-47]  -  \"%02X  %02X  %02X  %02X\"\t-  Impedance Mode or Not." \
				, buffersInput[0][44], buffersInput[0][45], buffersInput[0][46], buffersInput[0][47]);
			strAnalysis += strTemp;
			m_edtAnalysis.SetWindowTextA(strAnalysis);
		}

		// Re-submit this queue element to keep the queue full
		contextsInput[nINCount] = epBulkIn->BeginDataXfer(buffersInput[nINCount], totalTransferSize, &inOvLap[nINCount]);
		if (epBulkIn->NtStatus || epBulkIn->UsbdStatus)
		{
			// BeginDataXfer failed............
			// Time to bail out now............
			epBulkIn->Abort();
			for (int j = 0; j < QUEUE_SIZE; j++)
			{
				CloseHandle(inOvLap[j].hEvent);
				delete[] buffersInput[j];
			}
			delete[]contextsInput;

			CString strMsg;
			strMsg.Format("BeginDataXfer Failed during buffer re-cycle (NT Status = 0x%X and USBD Status = 0x%X). Bailing out...", epBulkIn->NtStatus, epBulkIn->UsbdStatus);
			AfxMessageBox(strMsg);
			return;
		}
		++nINCount;
	}

	epBulkIn->Abort();
	for (int j = 0; j < QUEUE_SIZE; j++)
	{
		CloseHandle(inOvLap[j].hEvent);
		delete[] buffersInput[j];
		delete[] contextsInput[j];
	}

	// Bail out......
	delete[]contextsInput;
	delete[] buffersInput;
	delete[] bufferOutput;
	CloseHandle(outOvLap.hEvent);

	return;
}

void CDialogDlg::DoUpdateADCInitiateStatus()
{
	CString strINData = m_strEndPointEnumerate0x88;
	CString strOutData = m_strEndPointEnumerate0x02;
	TCHAR* pEnd;
	BYTE inEpAddress = 0x0, outEpAddress = 0x0;

	// Extract the endpoint addresses........
	strINData = strINData.Right(4);
	strOutData = strOutData.Right(4);

	//inEpAddress = (BYTE)wcstoul(strINData.GetBuffer(0), &pEnd, 16);
	inEpAddress = strtol(strINData, &pEnd, 16);
	//outEpAddress = (BYTE)wcstoul(strOutData.GetBuffer(0), &pEnd, 16);
	outEpAddress = strtol(strOutData, &pEnd, 16);
	CCyUSBEndPoint* epBulkOut = m_selectedUSBDevice->EndPointOf(outEpAddress);
	CCyUSBEndPoint* epBulkIn = m_selectedUSBDevice->EndPointOf(inEpAddress);

	if (epBulkOut == NULL || epBulkIn == NULL) return;

	//
	// Get the max packet size (USB Frame Size).
	// For bulk burst transfer, this size represent bulk burst size.
	// Transfer size is now multiple USB frames defined by PACKETS_PER_TRANSFER
	//
	UCHAR QUEUE_SIZE = 1;
	//UCHAR PACKETS_PER_TRANSFER = 2;
	long totalTransferSize = epBulkIn->MaxPktSize * 2;
	epBulkIn->SetXferSize(totalTransferSize);

	long totalOutTransferSize = epBulkOut->MaxPktSize * 1;
	epBulkOut->SetXferSize(totalOutTransferSize);

	PUCHAR* buffersInput = new PUCHAR[QUEUE_SIZE];
	PUCHAR* contextsInput = new PUCHAR[QUEUE_SIZE];
	OVERLAPPED		inOvLap[MAX_QUEUE_SZ];

	// Allocate all the buffers for the queues
	for (int nCount = 0; nCount < QUEUE_SIZE; nCount++)
	{
		buffersInput[nCount] = new UCHAR[totalTransferSize];
		inOvLap[nCount].hEvent = CreateEvent(NULL, false, false, NULL);

		memset(buffersInput[nCount], 0xEF, totalTransferSize);
	}

	OVERLAPPED  outOvLap;
	UCHAR* bufferOutput = new UCHAR[totalOutTransferSize];
	outOvLap.hEvent = CreateEvent(NULL, false, false, NULL);

	BuildAtParameterQuery();
	BuildAtInstruction('R');

	for (int nCount = 0; nCount < g_atInstructionLength; nCount++)
	{
		bufferOutput[nCount] = g_atInstruction[nCount];
	}

	epBulkOut->TimeOut = TIMEOUT_PER_TRANSFER_MILLI_SEC;

	// Queue-up the first batch of transfer requests
	for (int nCount = 0; nCount < QUEUE_SIZE; nCount++)
	{
		////////////////////BeginDataXFer will kick start the IN transactions.................
		contextsInput[nCount] = epBulkIn->BeginDataXfer(buffersInput[nCount], totalTransferSize, &inOvLap[nCount]);
		if (epBulkIn->NtStatus || epBulkIn->UsbdStatus)
		{

			if (epBulkIn->UsbdStatus == USBD_STATUS_ENDPOINT_HALTED)
			{
				epBulkIn->Reset();
				epBulkIn->Abort();
				Sleep(50);
				contextsInput[nCount] = epBulkIn->BeginDataXfer(buffersInput[nCount], totalTransferSize, &inOvLap[nCount]);

			}
			if (epBulkIn->NtStatus || epBulkIn->UsbdStatus)
			{
				// BeginDataXfer failed
				// Handle the error now.
				epBulkIn->Abort();
				for (int j = 0; j < QUEUE_SIZE; j++)
				{
					CloseHandle(inOvLap[j].hEvent);
					delete[] buffersInput[j];
				}

				// Bail out......
				delete[]contextsInput;
				delete[] buffersInput;
				CString strMsg;
				strMsg.Format("BeginDataXfer Failed with (NT Status = 0x%X and USBD Status = 0x%X). Bailing out...", epBulkIn->NtStatus, epBulkIn->UsbdStatus);
				AfxMessageBox(strMsg);
				return;
			}
		}
	}

	// Mark the start time
	/*SYSTEMTIME objStartTime;
	GetSystemTime(&objStartTime);*/

	long nINCount = 0;
	while (nINCount < QUEUE_SIZE)
	{
		long readLength = totalTransferSize;

		epBulkOut->XferData(bufferOutput, g_atInstructionLength);

		//////////Wait till the transfer completion..///////////////////////////
		if (!epBulkIn->WaitForXfer(&inOvLap[nINCount], TIMEOUT_PER_TRANSFER_MILLI_SEC))
		{
			epBulkIn->Abort();
			if (epBulkIn->LastError == ERROR_IO_PENDING)
				WaitForSingleObject(inOvLap[nINCount].hEvent, TIMEOUT_PER_TRANSFER_MILLI_SEC);
		}

		////////////Read the trasnferred data from the device///////////////////////////////////////
		epBulkIn->FinishDataXfer(buffersInput[nINCount], readLength, &inOvLap[nINCount], contextsInput[nINCount]);

		int candidateADCInitiateStatus = 0;
		candidateADCInitiateStatus += buffersInput[0][4] << 24;
		candidateADCInitiateStatus += buffersInput[0][5] << 16;
		candidateADCInitiateStatus += buffersInput[0][6] << 8;
		candidateADCInitiateStatus += buffersInput[0][7];

		int candidateTotalDlNum = 0;
		candidateTotalDlNum += buffersInput[0][20] << 24;
		candidateTotalDlNum += buffersInput[0][21] << 16;
		candidateTotalDlNum += buffersInput[0][22] << 8;
		candidateTotalDlNum += buffersInput[0][23];

		if ((candidateADCInitiateStatus == 1) && ((candidateTotalDlNum == TOTAL_DL_NUM_18) || (candidateTotalDlNum == TOTAL_DL_NUM_36)))
		{
			m_bADCInitiateComplete = TRUE;
			m_buttonCheck18DlNum.EnableWindow(TRUE);
			m_buttonCheck18DlNum.SetCheck(candidateTotalDlNum == TOTAL_DL_NUM_18);
		}

		int impedanceTriggerSwitch = 0;
		impedanceTriggerSwitch += buffersInput[0][44] << 24;
		impedanceTriggerSwitch += buffersInput[0][45] << 16;
		impedanceTriggerSwitch += buffersInput[0][46] << 8;
		impedanceTriggerSwitch += buffersInput[0][47];

		m_buttonCheckImpedance.SetCheck(impedanceTriggerSwitch);

		// Re-submit this queue element to keep the queue full
		contextsInput[nINCount] = epBulkIn->BeginDataXfer(buffersInput[nINCount], totalTransferSize, &inOvLap[nINCount]);
		if (epBulkIn->NtStatus || epBulkIn->UsbdStatus)
		{
			// BeginDataXfer failed............
			// Time to bail out now............
			epBulkIn->Abort();
			for (int j = 0; j < QUEUE_SIZE; j++)
			{
				CloseHandle(inOvLap[j].hEvent);
				delete[] buffersInput[j];
			}
			delete[]contextsInput;

			CString strMsg;
			strMsg.Format("BeginDataXfer Failed during buffer re-cycle (NT Status = 0x%X and USBD Status = 0x%X). Bailing out...", epBulkIn->NtStatus, epBulkIn->UsbdStatus);
			AfxMessageBox(strMsg);
			return;
		}
		++nINCount;
	}

	epBulkIn->Abort();
	for (int j = 0; j < QUEUE_SIZE; j++)
	{
		CloseHandle(inOvLap[j].hEvent);
		delete[] buffersInput[j];
		delete[] contextsInput[j];
	}

	// Bail out......
	delete[]contextsInput;
	delete[] buffersInput;
	delete[] bufferOutput;
	CloseHandle(outOvLap.hEvent);

	return;
}

void CDialogDlg::OnBnClickedCheck18DlNum()
{
	m_buttonCheck18DlNum.EnableWindow(FALSE);
	m_bADCInitiateComplete = FALSE;
	UCHAR candidateTotalDlNum = (m_buttonCheck18DlNum.GetCheck()) ? TOTAL_DL_NUM_18 : TOTAL_DL_NUM_36;

	CString strOutData = m_strEndPointEnumerate0x02;
	TCHAR* pEnd;
	BYTE outEpAddress = 0x0;

	// Extract the endpoint addresses........
	strOutData = strOutData.Right(4);

	//outEpAddress = (BYTE)wcstoul(strOutData.GetBuffer(0), &pEnd, 16);
	outEpAddress = strtol(strOutData, &pEnd, 16);
	CCyUSBEndPoint* epBulkOut = m_selectedUSBDevice->EndPointOf(outEpAddress);

	if (epBulkOut == NULL) return;

	//
	// Get the max packet size (USB Frame Size).
	// For bulk burst transfer, this size represent bulk burst size.
	// Transfer size is now multiple USB frames defined by PACKETS_PER_TRANSFER
	//
	UCHAR QUEUE_SIZE = 1;
	UCHAR PACKETS_PER_TRANSFER = 1;
	long totalOutTransferSize = epBulkOut->MaxPktSize * PACKETS_PER_TRANSFER;
	epBulkOut->SetXferSize(totalOutTransferSize);

	OVERLAPPED  outOvLap;
	UCHAR* bufferOutput = new UCHAR[totalOutTransferSize];
	outOvLap.hEvent = CreateEvent(NULL, false, false, NULL);

	BuildAtParameterTotalDlNum(candidateTotalDlNum);
	BuildAtInstruction('S');

	for (int nCount = 0; nCount < g_atInstructionLength; nCount++)
	{
		bufferOutput[nCount] = g_atInstruction[nCount];
	}

	epBulkOut->TimeOut = TIMEOUT_PER_TRANSFER_MILLI_SEC;

	// Mark the start time
	/*SYSTEMTIME objStartTime;
	GetSystemTime(&objStartTime);*/

	epBulkOut->XferData(bufferOutput, g_atInstructionLength);

	// Bail out......
	delete[] bufferOutput;
	CloseHandle(outOvLap.hEvent);

	while (m_bADCInitiateComplete == FALSE)
	{
		Sleep(100);

		DoUpdateADCInitiateStatus();
	}
}

void CDialogDlg::OnBnClickedButtonSetSampleFreq()
{
	UINT sampleFreq = 0x9C40;
	char ch1[10];
	GetDlgItem(IDC_EDIT_SAMPLE_FREQ)->GetWindowText(ch1, 10);
	sampleFreq = atoi(ch1);
	ConfigADCSamplingRate(sampleFreq);
}

void CDialogDlg::OnBnClickedButtonTrigger()
{
	g_bButtonUSBTrigClicked = TRUE;

	char ch1[10];
	GetDlgItem(IDC_EDIT_TRIG_VALUE)->GetWindowText(ch1, 10);
	g_triggerValue = atoi(ch1);

	SendTriggerValue(g_triggerValue);

	while (g_bButtonUSBTrigClicked);

	CString strBytes(""), strTemp;
	for (int nCount = 0; nCount < DATA_PAGE_LENGTH; nCount++)
	{
		if (nCount % 16 == 0)
		{
			strTemp.Format("%04X", nCount);
			strBytes += strTemp;
			strBytes += "    ";
		}

		strTemp.Format("%02X", g_buffersTrigResult[nCount]);
		strBytes += strTemp;

		if ((nCount + 1) % 16 == 0)
		{
			strBytes += "\r\n";
		}
		else
		{
			strBytes += "  ";
		}
	}
	m_edtQueryResult.SetWindowText(strBytes);
}

void CDialogDlg::OnBnClickedButtonUartTrig()
{
	char portName[256] = { 0 };
	int SelParity;
	int SelDataBits;
	int SelStop;

	UpdateData(true);
	CString temp;
	m_PortNr.GetWindowText(temp);
#ifdef UNICODE
	strcpy_s(portName, 256, CW2A(temp.GetString()));
#else
	strcpy_s(portName, 256, temp.GetBuffer());
#endif	

	if ((!m_SerialPort.isOpen()) || (strcmp(m_SerialPort.getPortName(), temp) != 0)) ///没有打开串口
	{
		m_SerialPort.setReadIntervalTimeout(0);
		m_SerialPort.init(portName, itas109::BaudRate::BaudRate115200, itas109::Parity(ParityNone), itas109::DataBits(DataBits8), itas109::StopBits(StopOne));
		m_SerialPort.open();
	}

	g_bButtonUARTTrigClicked = TRUE;

	char ch1[10];
	GetDlgItem(IDC_EDIT_UART_TRIG)->GetWindowText(ch1, 10);
	g_uartTrigValue = atoi(ch1);

	SendUartTrigValue(g_uartTrigValue);

	while (g_bButtonUARTTrigClicked);

	CString strBytes(""), strTemp;
	for (int nCount = 0; nCount < DATA_PAGE_LENGTH; nCount++)
	{
		if (nCount % 16 == 0)
		{
			strTemp.Format("%04X", nCount);
			strBytes += strTemp;
			strBytes += "    ";
		}

		strTemp.Format("%02X", g_buffersTrigResult[nCount]);
		strBytes += strTemp;

		if ((nCount + 1) % 16 == 0)
		{
			strBytes += "\r\n";
		}
		else
		{
			strBytes += "  ";
		}
	}
	m_edtQueryResult.SetWindowText(strBytes);
}

void CDialogDlg::OnBnClickedCheckImpedance()
{
	if (m_bButtonADCSampleClicked)
	{
		m_buttonCheckImpedance.SetCheck(FALSE);
		AfxMessageBox(_T("请先关闭导联信号采集！！！"));
		return;
	}

	if (m_buttonCheckImpedance.GetCheck())
	{
		SendImpedanceInstruction(1);
		SetTimer(IDTIMER2, 1000, NULL);
	}
	else
	{
		SendImpedanceInstruction(0);
		KillTimer(IDTIMER2);
	}
}

void CDialogDlg::OnBnClickedButtonSend()
{
	GetDlgItem(IDC_EDIT_PRODUCT_ID)->SetFocus();

	char portName[256] = { 0 };
	int SelParity;
	int SelDataBits;
	int SelStop;

	UpdateData(true);
	CString temp;
	m_PortNr.GetWindowText(temp);
#ifdef UNICODE
	strcpy_s(portName, 256, CW2A(temp.GetString()));
#else
	strcpy_s(portName, 256, temp.GetBuffer());
#endif	

	if ((!m_SerialPort.isOpen()) || (strcmp(m_SerialPort.getPortName(), temp) != 0))
	{
		m_SerialPort.setReadIntervalTimeout(0);
		m_SerialPort.init(portName, itas109::BaudRate::BaudRate115200, itas109::Parity(ParityNone), itas109::DataBits(DataBits8), itas109::StopBits(StopOne));
		m_SerialPort.open();
	}

	CString strInstruction;
	m_edtProductId.GetWindowTextA(strInstruction);

	if ((strInstruction.GetLength() != 12) || (strInstruction.SpanIncluding("0123456789") != strInstruction))
	{
		AfxMessageBox(_T("请输入正确的8位生产日期加4位序列号，如：202411220001"));
		return;
	}

	BuildAtParameterUartWrite(strInstruction);
	BuildAtInstruction('W');

	m_SerialPort.writeData(g_atInstruction, g_atInstructionLength);
}

void CDialogDlg::onReadEvent(const char* portName, unsigned int readBufferLen)
{
	if (readBufferLen > 0)
	{
		char* data = new char[readBufferLen + 1]; // '\0'

		if (data)
		{
			int recLen = m_SerialPort.readData(data, readBufferLen);

			if (recLen > 0)
			{
				data[recLen] = '\0';

				CString strBytes(data);
				m_edtQueryResult.SetWindowTextA(strBytes);
			}

			delete[] data;
			data = NULL;
		}
	}
}


bool CDialogDlg::SurveyExistingComm()
{
	m_PortNr.ResetContent();

	//获取串口号
	std::vector<SerialPortInfo> m_portsList = CSerialPortInfo::availablePortInfos();
	for (size_t i = 0; i < m_portsList.size(); i++)
	{
		CString m_portName = CString();
#ifdef UNICODE
		int iLength;
		const char* _char = m_portsList[i].portName;
		iLength = MultiByteToWideChar(CP_ACP, 0, _char, strlen(_char) + 1, NULL, 0);
		MultiByteToWideChar(CP_ACP, 0, _char, strlen(_char) + 1, m_regKeyValue, iLength);
#else
		m_portName = m_portsList[i].portName;
#endif
		m_PortNr.AddString(m_portName);
	}
	m_PortNr.SetCurSel(0);

	return true;
}







