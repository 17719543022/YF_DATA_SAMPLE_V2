
// DialogDlg.h: 头文件
//

#pragma once
#include "CyAPI.h"
#include "ChartCtrl/ChartCtrl.h"
#include "ChartCtrl/ChartAxisLabel.h"
#include "ChartCtrl/ChartLineSerie.h"
#include "CSerialPort/SerialPort.h"
#include "CSerialPort/SerialPortInfo.h"
using namespace itas109;


// CDialogDlg 对话框
class CDialogDlg : public CDialogEx, public CSerialPortListener
{
// 构造
public:
	CDialogDlg(CWnd* pParent = nullptr);	// 标准构造函数
	virtual ~CDialogDlg();

// 对话框数据
#ifdef AFX_DESIGN_TIME
	enum { IDD = IDD_DIALOG_DIALOG };
#endif

protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV 支持

	void onReadEvent(const char* portName, unsigned int readBufferLen); // About CSerialPort

// 实现
protected:
	HICON m_hIcon;

	// 生成的消息映射函数
	virtual BOOL OnInitDialog();
	virtual LRESULT DefWindowProc(UINT message, WPARAM wParam, LPARAM lParam);

	afx_msg void OnSysCommand(UINT nID, LPARAM lParam);
	afx_msg void OnPaint();
	afx_msg HCURSOR OnQueryDragIcon();
	DECLARE_MESSAGE_MAP()
public:
	afx_msg void OnCbnSelchangeComboDevices();
	afx_msg void OnBnClickedButtonAdcSample();
	afx_msg void OnBnClickedButtonTrigger();
	afx_msg void OnBnClickedButtonUartTrig();
	afx_msg void OnBnClickedButtonStatus();
	afx_msg void OnBnClickedCheck18DlNum();
	afx_msg void OnBnClickedButtonSetSampleFreq();
	afx_msg void OnBnClickedCheckImpedance();
	afx_msg void OnBnClickedButtonSend();
	afx_msg void OnTimer(UINT_PTR nIDEvent);
private:
	bool SurveyExistingDevices();
	bool SurveyExistingComm();
	bool EnumerateEndpointForTheSelectedDevice();
	void ConfigADCSamplingRate(UINT samplingRate);
	void StartAdcSample();
	void StopAdcSample();
	void SendTriggerValue(UCHAR value);
	void SendUartTrigValue(UCHAR value);
	void SendImpedanceInstruction(UINT dlNum);
	static DWORD WINAPI PerformADCSampling(LPVOID lParam);
	DWORD ClearUSBFIFO();
	void DataBuffInit();
	void ChartCtrlInit();
	void DoQuery();
	void DoUpdateADCInitiateStatus();
	CComboBox m_comboDevices;
	CCyUSBDevice* m_selectedUSBDevice;
	CButton m_buttonVersion;
	CButton m_buttonADCSample;
	CButton m_buttonCheck18DlNum;
	CButton m_buttonSetSampleFreq;
	CButton m_buttonUSBTrig;
	CButton m_buttonUARTTrig;
	CButton m_buttonCheckImpedance;
	CString m_strEndPointEnumerate0x02;
	CString m_strEndPointEnumerate0x04;
	CString m_strEndPointEnumerate0x86;
	CString m_strEndPointEnumerate0x88;
	CEdit m_edtQueryResult;
	CEdit m_edtAnalysis;
	CEdit m_edtSampleFreq;
	CEdit m_edtTriggerValue;
	CEdit m_edtUartTrigValue;
	CEdit m_edtImpedance;
	CEdit m_edtProductId;
	CWinThread* m_pThread;
	bool m_bButtonADCSampleClicked;
	bool m_bButtonImpedanceClicked;
	bool m_bADCInitiateComplete;
	UINT m_uDlNum;
	CChartCtrl m_ChartCtrl;
	CChartLineSerie* pLineSeries;
	UINT m_AxisMin;
	UINT m_AxisMax;
	CComboBox m_PortNr;
	CSerialPort m_SerialPort;
};
