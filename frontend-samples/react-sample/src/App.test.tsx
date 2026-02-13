import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import '@testing-library/jest-dom'
import App from './App'

// Mock fetch
global.fetch = vi.fn()

describe('App', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders the app title', () => {
    render(<App />)
    expect(screen.getByText('Azure APIM React Sample')).toBeInTheDocument()
  })

  it('calls API on GET button click', async () => {
    const mockResponse = {
      message: 'Hello, Test User!',
      timestamp: '2024-01-01T00:00:00Z',
      functionName: 'sample-api-function',
      version: '1.0.0',
    }

    ;(global.fetch as any).mockResolvedValueOnce({
      ok: true,
      json: async () => mockResponse,
    })

    render(<App />)
    
    const input = screen.getByPlaceholderText('Enter a name')
    fireEvent.change(input, { target: { value: 'Test User' } })

    const getButton = screen.getByText('Call API (GET)')
    fireEvent.click(getButton)

    await waitFor(() => {
      expect(screen.getByText('Success!')).toBeInTheDocument()
    })

    expect(screen.getByText(/Hello, Test User!/)).toBeInTheDocument()
  })

  it('displays error on API failure', async () => {
    ;(global.fetch as any).mockResolvedValueOnce({
      ok: false,
      status: 500,
    })

    render(<App />)
    
    const getButton = screen.getByText('Call API (GET)')
    fireEvent.click(getButton)

    await waitFor(() => {
      expect(screen.getByText(/Error:/)).toBeInTheDocument()
    })
  })

  it('includes subscription key in headers when provided', async () => {
    const mockResponse = {
      message: 'Hello, Test!',
      timestamp: '2024-01-01T00:00:00Z',
      functionName: 'sample-api-function',
      version: '1.0.0',
    }

    ;(global.fetch as any).mockResolvedValueOnce({
      ok: true,
      json: async () => mockResponse,
    })

    render(<App />)
    
    const keyInput = screen.getByPlaceholderText('Your APIM subscription key')
    fireEvent.change(keyInput, { target: { value: 'test-key-123' } })

    const getButton = screen.getByText('Call API (GET)')
    fireEvent.click(getButton)

    await waitFor(() => {
      expect(global.fetch).toHaveBeenCalledWith(
        expect.any(String),
        expect.objectContaining({
          headers: expect.objectContaining({
            'Ocp-Apim-Subscription-Key': 'test-key-123',
          }),
        })
      )
    })
  })
})
