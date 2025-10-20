
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
CDialogDlg::CDialogDlg(CWnd* pParent /*=nullptr*/)
	: CDialogEx(IDD_DIALOG_DIALOG, pParent)
{
	m_hIcon = AfxGetApp()->LoadIcon(IDR_MAINFRAME);
	m_selectedUSBDevice = NULL;
	m_strEndPointEnumerate0x02 = _T("");
	m_strEndPointEnumerate0x86 = _T("");
	m_bButtonADCSampleClicked = FALSE;
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
	DDX_Control(pDX, IDC_BUTTON_ADC_SAMPLE, m_buttonADCSample);
	DDX_Control(pDX, IDC_CUSTOM_SHOW, m_ChartCtrl);
	DDX_Control(pDX, IDC_EDIT_DL_NUM, m_edtDlNum);
	DDX_Control(pDX, IDC_EDIT_QUERY, m_edtDebug);
}

BEGIN_MESSAGE_MAP(CDialogDlg, CDialogEx)
	ON_WM_SYSCOMMAND()
	ON_WM_PAINT()
	ON_WM_QUERYDRAGICON()
	ON_CBN_SELCHANGE(IDC_COMBO_DEVICES, &CDialogDlg::OnCbnSelchangeComboDevices)
	ON_BN_CLICKED(IDC_BUTTON_ADC_SAMPLE, &CDialogDlg::OnBnClickedButtonAdcSample)
	ON_WM_TIMER()
END_MESSAGE_MAP()

#define DATA_SHOW_LENGTH 1000
#define IDTIMER1 1

int g_DlNum = 1;
unsigned short g_xBuff[DATA_SHOW_LENGTH] = { 0 };
long g_yBuff[DATA_SHOW_LENGTH] = { 0 };
double XValues[DATA_SHOW_LENGTH] = { 0 };
double YValues[DATA_SHOW_LENGTH] = { 0 };
bool bKInstructionSend = FALSE;
UINT16 g_writeIndex = 0;
UINT16 writeIndex = 0;
UCHAR g_historyBuffer[512 * 10] = { 0 };
UINT16 g_historyIndex = 0;
bool bBlockWork = TRUE;
UCHAR g_frameBuffer[1024] = { 0 };
UINT16 g_frameValidLength = 0;
UINT32 frameNumber = 0;
SYSTEMTIME objStartTime;

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
	SurveyExistingDevices();
	EnumerateEndpointForTheSelectedDevice();

	UpdateData(FALSE);

	DataBuffInit();
	ChartCtrlInit();

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

		m_bButtonADCSampleClicked = FALSE;
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
					m_strEndPointEnumerate0x86 = strData;
			}
		}
	}

	this->m_buttonADCSample.EnableWindow(TRUE);

	return TRUE;
}

void CDialogDlg::OnBnClickedButtonAdcSample()
{
	char ch1[10];
	GetDlgItem(IDC_EDIT_DL_NUM)->GetWindowText(ch1, 10);
	g_DlNum = atoi(ch1);
	if ((g_DlNum < 1) || (g_DlNum > 36))
	{
		AfxMessageBox(_T("请确认输入了正确的导联号！！！"));
		return;
	}

	writeIndex = 0;

	if (m_bButtonADCSampleClicked == FALSE)
	{
		m_bButtonADCSampleClicked = TRUE;

		m_buttonADCSample.SetWindowText("停止");

		m_pThread = AfxBeginThread((AFX_THREADPROC)PerformADCSampling, (LPVOID)this);

		SetTimer(IDTIMER1, 100, NULL);
	}
	else
	{
		m_bButtonADCSampleClicked = FALSE;

		m_buttonADCSample.SetWindowText("正式启动");

		WaitForSingleObject(m_pThread->m_hThread, 100);
		m_pThread = NULL;

		KillTimer(IDTIMER1);

		if (!bBlockWork)
		{
			FILE* fh = fopen("../samples/info.txt", "w");

			for (int hIndex = 0; hIndex < 10 * 512; hIndex++)
			{
				fprintf(fh, "%02X", g_historyBuffer[hIndex]);

				if ((hIndex + 1) % 500 == 0)
				{
					fprintf(fh, "\r");
				}
				else
				{
					fprintf(fh, "  ");
				}
			}

			fclose(fh);
			fh = NULL;
		}
	}
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
			YValues[i] = (((g_yBuff[i] * 2500.0) / pow(2, 23)) / 3.57);
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

void CDialogDlg::LogScroll(CString log)
{
	int nLen = m_edtDebug.GetWindowTextLength();
	m_edtDebug.SetSel(nLen, nLen);
	m_edtDebug.ReplaceSel(log);
}

DWORD WINAPI CDialogDlg::PerformADCSampling(LPVOID lParam)
{
	CDialogDlg* pThis = (CDialogDlg*)lParam;

	CString strINData = pThis->m_strEndPointEnumerate0x86;
	CString strOutData = pThis->m_strEndPointEnumerate0x02;
	TCHAR* pEnd;
	BYTE inEpAddress = 0x0, outEpAddress = 0x0;

	// Extract the endpoint addresses........
	strINData = strINData.Right(4);
	strOutData = strOutData.Right(4);

	//inEpAddress = (BYTE)wcstoul(strINData.GetBuffer(0), &pEnd, 16);
	inEpAddress = strtol(strINData, &pEnd, 16);
	//outEpAddress = (BYTE)wcstoul(strOutData.GetBuffer(0), &pEnd, 16);
	outEpAddress = strtol(strOutData, &pEnd, 16);
	CCyUSBEndPoint* epBulkOut = pThis->m_selectedUSBDevice->EndPointOf(outEpAddress);
	CCyUSBEndPoint* epBulkIn = pThis->m_selectedUSBDevice->EndPointOf(inEpAddress);

	if (epBulkOut == NULL || epBulkIn == NULL) return -1;

	//
	// Get the max packet size (USB Frame Size).
	// For bulk burst transfer, this size represent bulk burst size.
	// Transfer size is now multiple USB frames defined by PACKETS_PER_TRANSFER
	//
	UCHAR QUEUE_SIZE = 16;
	UCHAR PACKETS_PER_TRANSFER = 1;
	long totalTransferSize = epBulkIn->MaxPktSize * PACKETS_PER_TRANSFER;
	epBulkIn->SetXferSize(totalTransferSize);

	long totalOutTransferSize = epBulkOut->MaxPktSize * PACKETS_PER_TRANSFER;
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

	//CString strAmpDetectCommand = "@KD0071234567800000320876FC7D&KD0071234567800000320876FC7D#0";
	//for (int nCount = 0; nCount < strAmpDetectCommand.GetLength(); nCount++)
	//{
	//	bufferOutput[nCount] = strAmpDetectCommand[nCount];
	//}

	bufferOutput[0] = 0x55;
	bufferOutput[1] = 0xAA;
	bufferOutput[2] = 0xCB;
	bufferOutput[3] = 0xCD;
	bufferOutput[4] = 0x10;
	bufferOutput[5] = 0x50;
	bufferOutput[6] = 0x10;
	bufferOutput[7] = 0x27;
	bufferOutput[8] = 0x00;
	bufferOutput[9] = 0x00;
	bufferOutput[10] = 0x01;
	bufferOutput[11] = 0x24;
	bufferOutput[12] = 0x00;
	bufferOutput[13] = 0x00;
	bufferOutput[14] = 0x00;
	bufferOutput[15] = 0x00;
	bufferOutput[16] = 0x00;
	bufferOutput[17] = 0x00;
	bufferOutput[18] = 0x00;
	bufferOutput[19] = 0x00;
	bufferOutput[20] = 0x00;
	bufferOutput[21] = 0x00;
	bufferOutput[22] = 0x00;
	bufferOutput[23] = 0x00;
	bufferOutput[24] = 0x00;
	bufferOutput[25] = 0x00;
	bufferOutput[26] = 0x00;
	bufferOutput[27] = 0x00;
	bufferOutput[28] = 0x00;
	bufferOutput[29] = 0x03;
	bufferOutput[30] = 0x00;
	bufferOutput[31] = 0x00;
	bufferOutput[32] = 0x00;
	bufferOutput[33] = 0x00;
	bufferOutput[34] = 0x00;
	bufferOutput[35] = 0x00;
	bufferOutput[36] = 0x00;
	bufferOutput[37] = 0x00;
	bufferOutput[38] = 0x00;
	bufferOutput[39] = 0xA3;

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
				return -2;
			}
		}
	}

	// Mark the start time
	/*SYSTEMTIME objStartTime;
	GetSystemTime(&objStartTime);*/

	long nCount = 0;
	FILE* fp = NULL;
	while (pThis->m_bButtonADCSampleClicked == TRUE)
	{
		if ((fp == NULL) && (pThis->m_bButtonADCSampleClicked == TRUE))
		{
			fp = fopen("../samples/data.txt", "w");
		}

		long readLength = totalTransferSize;
		long writeLength = 40;

		if (bKInstructionSend == FALSE)
		{
			bKInstructionSend = TRUE;
			epBulkOut->XferData(bufferOutput, writeLength);
		}

		//////////Wait till the transfer completion..///////////////////////////
		if (!epBulkIn->WaitForXfer(&inOvLap[nCount], TIMEOUT_PER_TRANSFER_MILLI_SEC))
		{
			epBulkIn->Abort();
			if (epBulkIn->LastError == ERROR_IO_PENDING)
				WaitForSingleObject(inOvLap[nCount].hEvent, TIMEOUT_PER_TRANSFER_MILLI_SEC);
		}

		////////////Read the trasnferred data from the device///////////////////////////////////////
		epBulkIn->FinishDataXfer(buffersInput[nCount], readLength, &inOvLap[nCount], contextsInput[nCount]);

		//for (int mCount = 0; mCount < readLength; mCount++)
		//{
		//	fprintf(fp, "%02X", buffersInput[nCount][mCount]);
		//
		//	//if ((mCount + 1) % 16 == 0)
		//	//{
		//	//	fprintf(fp, "\r");
		//	//}
		//	//else
		//	//{
		//	//	fprintf(fp, "  ");
		//	//}
		//
		//	writeIndex = (writeIndex + 1) % 500;
		//
		//	if (writeIndex == 0)
		//	{
		//		fprintf(fp, "\r");
		//	}
		//	else
		//	{
		//		fprintf(fp, "  ");
		//	}
		//}

		if (bBlockWork)
		{
			if (g_historyIndex + readLength > 512 * 10)
			{
				g_historyIndex = 0;
				memset(g_historyBuffer, 0xEF, 512 * 10);
				memmove(g_historyBuffer, buffersInput[nCount], readLength);
			}
			else
			{
				memmove(&g_historyBuffer[g_historyIndex], buffersInput[nCount], readLength);
				g_historyIndex = g_historyIndex + readLength;
			}

			if (g_frameValidLength > 512)
			{
				memset(g_frameBuffer, 0x00, 1024);
				g_frameValidLength = 0;
			}

			memmove(&g_frameBuffer[g_frameValidLength], buffersInput[nCount], readLength);
			g_frameValidLength += readLength;

			for (int nCount = 0; nCount < 2; nCount++)
			{
				for (int mCount = 0; mCount + 500 - 1 < g_frameValidLength; mCount++)
				{
					if (g_frameBuffer[mCount] == 0xAA)
					{
						if (g_frameBuffer[mCount + 1] == 0x55)
						{
							if (g_frameBuffer[mCount + 2] == 0xCD)
							{
								if (g_frameBuffer[mCount + 3] == 0xCB)
								{
									if (g_frameBuffer[mCount + 4] == 0x10)
									{
										if (g_frameBuffer[mCount + 500 - 1] == 0x5C)
										{
											UINT32 frameNumberNext = 0;
											frameNumberNext += g_frameBuffer[mCount + 5];
											frameNumberNext += g_frameBuffer[mCount + 6] << 8;
											frameNumberNext += g_frameBuffer[mCount + 7] << 16;
											frameNumberNext += g_frameBuffer[mCount + 8] << 24;

											if ((frameNumberNext - 1 != frameNumber) && (frameNumber != 0))
											{
												bBlockWork = FALSE;

												GetSystemTime(&objStartTime);
												CString strTemp = _T("");
												strTemp.Format("%d/%d/%d/%d:\t\tframeNumber: %d, frameNumberNext: %d\r\n"
													, objStartTime.wHour, objStartTime.wMinute, objStartTime.wSecond, objStartTime.wMilliseconds, frameNumber, frameNumberNext);
												//pThis->m_edtDebug.SetWindowTextA(strTemp);
												pThis->LogScroll(strTemp);
											}
											frameNumber = frameNumberNext;

											g_yBuff[g_writeIndex] = g_frameBuffer[mCount + 9 + (g_DlNum - 1) * 3];
											g_yBuff[g_writeIndex] += g_frameBuffer[mCount + 9 + (g_DlNum - 1) * 3 + 1] << 8;
											g_yBuff[g_writeIndex] += g_frameBuffer[mCount + 9 + (g_DlNum - 1) * 3 + 2] << 16;
											if (g_yBuff[g_writeIndex] == 0x800000)
											{
												g_yBuff[g_writeIndex] -= 0x800000;
											}
											else if (g_yBuff[g_writeIndex] > 0x800000)
											{
												g_yBuff[g_writeIndex] -= 0x800000 * 2;
											}

											g_writeIndex = (g_writeIndex + 1) % DATA_SHOW_LENGTH;

											g_frameValidLength -= (500 + mCount);
											memmove(g_frameBuffer, &g_frameBuffer[mCount + 500], g_frameValidLength);
										}
									}
								}
							}
						}
					}
				}
			}
		}

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
			if ((pThis->m_bButtonADCSampleClicked == FALSE) && (fp != NULL))
			{
				fclose(fp);
				fp = NULL;
			}
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
	delete[] bufferOutput;
	CloseHandle(outOvLap.hEvent);

	return 0;
}


